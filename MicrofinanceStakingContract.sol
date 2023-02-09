// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IReserveDeployer {
    function createReserve(
        address _stakerContract,
        address _tokenContract,
        uint8 _tokenDecimals,
        uint256 _pid
    ) external returns (address);
}

interface IReserve is IERC20Metadata {
    function mintCollateralToken(
        address to,
        uint256 amount
    ) external returns (bool);

    function burnCollateralToken(
        address from,
        uint256 amount
    ) external returns (bool);

    function resetAllowance() external;
}

contract Staking is Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeMath for uint256;

    enum PoolType {
        Staking,
        Loan,
        ConstrainedLoan
    }

    enum TransactionType {
        Staking,
        Borrow
    }

    struct Transaction {
        TransactionType transactionType;
        uint256 amount;
        uint256 time;
        uint256 pendingInterest;
        uint256 paidOutForDuration;
        uint256 paidOutForQuarters;
    }

    struct TokenInfo {
        IERC20Metadata token;
        IReserve reserve;
        uint8 decimals;
        string name;
        string symbol;
    }

    struct DepositLimiters {
        uint256 duration; // a.k.a. Lockup period
        uint256 startTime; // Applicable for poolType Staking and Constrained Loan
        uint256 endTime; // Applicable for poolType Staking and Constrained Loan
        uint256 limitPerUser;
        uint256 capacity;
        uint256 maxUtilisation; // Applicable for poolType Loan and Constrained Loan
    }

    struct Funds {
        uint256 balance;
        uint256 loanedBalance;
    }

    struct UserInfo {
        bool isAPoolUser;
        bool isWhitelisted;
        Transaction transaction;
    }

    struct PoolInfo {
        string poolName;
        PoolType poolType;
        uint256 apy; // "Max. APY" in case of poolType Loan
        bool paused;
        bool quarterlyPayout; // Applicable for poolType Staking
        bool interestPayoutsStarted; // Applicable for poolType Staking
        uint256 uniqueUsers;
        TokenInfo tokenInfo;
        Funds funds;
        DepositLimiters depositLimiters;
    }

    IReserveDeployer private immutable _reserveDeployer;

    PoolInfo[] private _poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) private _isACollateralToken;

    string private constant _INTEREST_PAYOUT_NOT_STARTED =
        'Interest payout not started';
    string private constant _UNSUPPORTED_POOL_TYPE =
        'unsupported pool for this action';
    string private constant _AMOUNT_GREATER_THAN_TRANSACTION =
        'amount greater than the transaction amount';
    uint256 private constant _ONE_HUNDRED = 100;
    uint256 private constant _PERCENTAGE_PRECISION = 1 ether;
    uint256 private constant _ONE_YEAR = 365 days;
    uint256 private constant _ONE_QUARTER = 90 days;
    uint256 private constant _ZERO = 0;
    uint256 private constant _ONE = 1;

    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    event RewardHarvested(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event PoolPaused(uint256 indexed _pid, bool _flag);

    event Whitelisted(address indexed user, uint256 indexed pid, bool status);

    event StakeTransferred(
        uint256 indexed pid,
        address from,
        address to,
        uint256 amount
    );

    event Borrowed(address indexed user, uint256 indexed pid, uint256 amount);
    event Repaid(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IReserveDeployer reserveDeployer, address _owner) {
        _reserveDeployer = reserveDeployer;
        _transferOwnership(_owner);
    }

    function setPoolPaused(uint256 _pid, bool _flag) external onlyOwner {
        _poolInfo[_pid].paused = _flag;
        emit PoolPaused(_pid, _flag);
    }

    function startInterest(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = _poolInfo[_pid];

        require(
            pool.poolType == PoolType.Staking ||
                pool.poolType == PoolType.ConstrainedLoan,
            _UNSUPPORTED_POOL_TYPE
        );
        require(
            !pool.interestPayoutsStarted,
            'Interest payouts already started'
        );

        // Interest will be calculated from now and
        // further deposits will be disabled immediately
        pool.depositLimiters.endTime = block.timestamp;

        // Enable payouts
        pool.interestPayoutsStarted = true;
    }

    /**
     * @dev Should allow users to withdraw rewards quarterly without withdrawing
     * any amount from their stake if `quarterlyPayout` is enabled for the pool
     */
    function claimQuarterlyPayout(uint256 _pid) external {
        PoolInfo memory pool = _poolInfo[_pid];
        Transaction storage transaction = userInfo[_pid][msg.sender]
            .transaction;

        require(
            pool.poolType == PoolType.Staking ||
                pool.poolType == PoolType.ConstrainedLoan,
            'quarterlyPayout not valid for poolType Loan'
        );
        require(pool.quarterlyPayout, 'quarterlyPayout disabled for this pool');

        require(
            block.timestamp > pool.depositLimiters.endTime &&
                pool.interestPayoutsStarted,
            _INTEREST_PAYOUT_NOT_STARTED
        );

        uint256 timeSinceDepositsEnd = block.timestamp.sub(
            pool.depositLimiters.endTime
        );
        uint256 timeSinceLastTransaction = block.timestamp.sub(
            transaction.time
        );

        uint256 quartersPassedSinceDepositsEnd = timeSinceDepositsEnd.div(
            _ONE_QUARTER
        );
        require(quartersPassedSinceDepositsEnd > _ZERO, 'too early');

        require(
            transaction.paidOutForQuarters < quartersPassedSinceDepositsEnd,
            'already withdrawn'
        );
        transaction.paidOutForQuarters = quartersPassedSinceDepositsEnd;

        uint256 duration;

        if (timeSinceLastTransaction < timeSinceDepositsEnd) {
            // Use the last transaction time
            duration = timeSinceLastTransaction;

            if (
                duration.add(transaction.paidOutForDuration) >
                pool.depositLimiters.duration
            ) {
                duration = pool.depositLimiters.duration.sub(
                    transaction.paidOutForDuration
                );
            }

            // Update the transaction time, since the rewards till this duration will be paid
            transaction.time = block.timestamp;
        } else {
            // Use the duration according to the count of full quarters passed
            duration = quartersPassedSinceDepositsEnd.mul(_ONE_QUARTER);
            // Update the transaction time till the paid duration

            if (duration > pool.depositLimiters.duration) {
                duration = pool.depositLimiters.duration;
            }

            transaction.time = pool.depositLimiters.endTime.add(duration);
        }

        _transferRewards(_pid, transaction.amount, duration);
    }

    function whitelist(
        uint256 _pid,
        address _user,
        bool _status
    ) external onlyOwner {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        require(
            pool.poolType == PoolType.Loan ||
                pool.poolType == PoolType.ConstrainedLoan,
            _UNSUPPORTED_POOL_TYPE
        );

        user.isWhitelisted = _status;

        emit Whitelisted(_user, _pid, _status);
    }

    function createPool(PoolInfo memory poolInfo) external onlyOwner {
        if (
            poolInfo.poolType == PoolType.Staking ||
            poolInfo.poolType == PoolType.ConstrainedLoan
        ) {
            poolInfo.depositLimiters.startTime = poolInfo
                .depositLimiters
                .startTime < block.timestamp
                ? block.timestamp
                : poolInfo.depositLimiters.startTime;

            require(
                poolInfo.depositLimiters.startTime <
                    poolInfo.depositLimiters.endTime,
                'end time should be after start time'
            );
        } else {
            poolInfo.depositLimiters.startTime = _ZERO;
            poolInfo.depositLimiters.endTime = _ZERO;
        }

        poolInfo.funds.balance = _ZERO;
        poolInfo.funds.loanedBalance = _ZERO;
        poolInfo.uniqueUsers = _ZERO;
        poolInfo.interestPayoutsStarted = false;

        poolInfo.tokenInfo.decimals = poolInfo.tokenInfo.token.decimals();
        poolInfo.tokenInfo.name = poolInfo.tokenInfo.token.name();
        poolInfo.tokenInfo.symbol = poolInfo.tokenInfo.token.symbol();

        if (
            poolInfo.poolType == PoolType.Loan ||
            poolInfo.poolType == PoolType.ConstrainedLoan
        ) {
            require(
                poolInfo.depositLimiters.maxUtilisation <= _ONE_HUNDRED,
                'Utilisation can be maximum 100%'
            );
        } else {
            poolInfo.depositLimiters.maxUtilisation = _ONE_HUNDRED;
        }

        uint256 _pid = _poolInfo.length;

        address reserve = _reserveDeployer.createReserve(
            address(this),
            address(poolInfo.tokenInfo.token),
            poolInfo.tokenInfo.decimals,
            _pid
        );

        _isACollateralToken[reserve] = true;

        poolInfo.tokenInfo.reserve = IReserve(reserve);

        _poolInfo.push(poolInfo);
    }

    function editPool(
        uint256 _pid,
        PoolInfo memory _newPoolInfo
    ) external onlyOwner {
        PoolInfo memory pool = _poolInfo[_pid];

        // Perserve some info
        _newPoolInfo.poolType = pool.poolType;
        _newPoolInfo.uniqueUsers = pool.uniqueUsers;

        _newPoolInfo.funds.balance = pool.funds.balance;
        _newPoolInfo.funds.loanedBalance = pool.funds.loanedBalance;

        _newPoolInfo.tokenInfo.token = pool.tokenInfo.token;
        _newPoolInfo.tokenInfo.reserve = pool.tokenInfo.reserve;

        if (
            pool.poolType == PoolType.Loan ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            require(
                _newPoolInfo.depositLimiters.maxUtilisation <= _ONE_HUNDRED,
                'maxUtilisation cannot exceed 100%'
            );

            uint256 currentUtilisation = _getPoolUtilisation(_pid);

            require(
                _newPoolInfo.depositLimiters.maxUtilisation.mul(
                    _PERCENTAGE_PRECISION
                ) >= currentUtilisation,
                'should not set max utilisation less than current'
            );
        } else {
            _newPoolInfo.depositLimiters.maxUtilisation = _ONE_HUNDRED;
        }

        _poolInfo[_pid] = _newPoolInfo;
    }

    /**
     * @dev Deposits the chosen _amount with the specified constraints
     */
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction storage transaction = user.transaction;

        if (
            pool.poolType == PoolType.Staking ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            require(
                block.timestamp >= pool.depositLimiters.startTime,
                'deposits not started at this time'
            );

            require(
                block.timestamp <= pool.depositLimiters.endTime,
                'deposits duration ended'
            );
        }

        if (transaction.transactionType == TransactionType.Borrow) {
            require(
                transaction.amount == _ZERO,
                'Should repay all borrowed before staking'
            );
        }

        require(!pool.paused, 'Pool Paused');
        require(
            transaction.amount.add(_amount) <=
                pool.depositLimiters.limitPerUser,
            'amount exceeds limit per user'
        );
        require(
            pool.funds.balance.add(_amount) <= pool.depositLimiters.capacity,
            'pool capacity reached'
        );

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.reserve),
            _amount
        );

        if (transaction.transactionType != TransactionType.Staking) {
            transaction.transactionType = TransactionType.Staking;
        }

        transaction.amount = transaction.amount.add(_amount);
        transaction.time = block.timestamp;

        pool.funds.balance = pool.funds.balance.add(_amount);

        _addUniqueUser(_pid);

        pool.tokenInfo.reserve.mintCollateralToken(msg.sender, _amount);

        emit Deposited(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction storage transaction = user.transaction;

        require(
            transaction.transactionType == TransactionType.Staking,
            'not staked'
        );
        require(
            _amount <= transaction.amount,
            _AMOUNT_GREATER_THAN_TRANSACTION
        );

        if (
            pool.poolType == PoolType.Staking ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            require(pool.interestPayoutsStarted, _INTEREST_PAYOUT_NOT_STARTED);
            require(
                block.timestamp >=
                    pool.depositLimiters.endTime.add(
                        pool.depositLimiters.duration
                    ),
                'withdrawing too early'
            );
        }

        if (
            pool.poolType == PoolType.ConstrainedLoan ||
            pool.poolType == PoolType.Loan
        ) {
            require(
                pool.funds.balance >= pool.funds.loanedBalance.add(_amount),
                'amount is currently utilised'
            );

            uint256 projectedUtilisation = _calculatePercentage(
                pool.funds.loanedBalance,
                pool.funds.balance.sub(_amount)
            );

            require(
                projectedUtilisation <=
                    pool.depositLimiters.maxUtilisation.mul(
                        _PERCENTAGE_PRECISION
                    ),
                'pool utilisation will max out if withdrawn'
            );
        }

        // Update user states
        transaction.amount = transaction.amount.sub(_amount);

        uint256 originalAmount = _amount;

        uint256 transactionTime = transaction.time;

        transaction.time = block.timestamp;

        if (
            pool.poolType == PoolType.Staking ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            // Send rewards according to APY
            uint256 timeSinceDepositsEnd = block.timestamp.sub(
                pool.depositLimiters.endTime
            );

            uint256 timeSinceLastTransaction = block.timestamp.sub(
                transactionTime
            );

            uint256 duration;

            if (timeSinceLastTransaction < timeSinceDepositsEnd) {
                duration = timeSinceLastTransaction;

                if (
                    duration.add(transaction.paidOutForDuration) >
                    pool.depositLimiters.duration
                ) {
                    duration = pool.depositLimiters.duration.sub(
                        transaction.paidOutForDuration
                    );
                }
            } else {
                duration = timeSinceDepositsEnd;

                if (duration > pool.depositLimiters.duration) {
                    duration = pool.depositLimiters.duration;
                }
            }

            _transferRewards(_pid, _amount, duration);
        } else if (pool.poolType == PoolType.Loan) {
            // Send rewards according to the current interest paid by the borrowers
            _amount = _amount.mul(pool.funds.balance).div(
                pool.tokenInfo.reserve.totalSupply()
            );
        }

        // Update global states
        pool.funds.balance = pool.funds.balance.sub(_amount);

        _removeUserIfStakeIsEmpty(_pid);

        pool.tokenInfo.reserve.burnCollateralToken(msg.sender, originalAmount);

        _resetReserveAllowanceIfRequired(
            pool.tokenInfo.reserve,
            pool.tokenInfo.token,
            _amount
        );

        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.reserve),
            msg.sender,
            _amount
        );

        emit Withdrawn(msg.sender, _pid, _amount);
    }

    function borrow(uint256 _pid, uint256 _amount) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = _poolInfo[_pid];
        Transaction storage transaction = userInfo[_pid][msg.sender]
            .transaction;

        if (transaction.transactionType == TransactionType.Staking) {
            require(
                transaction.amount == _ZERO,
                'Should withdraw all staked before borrowing'
            );
        }
        require(
            pool.poolType == PoolType.Loan ||
                pool.poolType == PoolType.ConstrainedLoan,
            _UNSUPPORTED_POOL_TYPE
        );
        require(user.isWhitelisted, 'Only whitelisted can borrow');
        require(!pool.paused, 'Pool paused');
        require(pool.funds.balance > _ZERO, 'Nothing deposited');

        uint256 projectedUtilisation = _calculatePercentage(
            pool.funds.loanedBalance.add(_amount),
            pool.funds.balance
        );

        require(
            projectedUtilisation <=
                pool.depositLimiters.maxUtilisation.mul(_PERCENTAGE_PRECISION),
            'utilisation will max out if borrowed'
        );

        // Update global states
        pool.funds.loanedBalance = pool.funds.loanedBalance.add(_amount);

        _resetReserveAllowanceIfRequired(
            pool.tokenInfo.reserve,
            pool.tokenInfo.token,
            _amount
        );

        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.reserve),
            msg.sender,
            _amount
        );

        if (transaction.transactionType != TransactionType.Borrow) {
            transaction.transactionType = TransactionType.Borrow;
        }

        if (pool.poolType != PoolType.ConstrainedLoan) {
            // On Constrained Loan pool type the borrower only has to pay
            // according to the current interest withdrawn. So, there is no point of storing
            // the unpaid interest
            transaction.pendingInterest = transaction.pendingInterest.add(
                interestSinceLastUpdate(_pid, msg.sender)
            );
        }

        transaction.amount = transaction.amount.add(_amount);
        transaction.time = block.timestamp;

        _addUniqueUser(_pid);

        emit Borrowed(msg.sender, _pid, _amount);
    }

    function repay(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction storage transaction = user.transaction;

        require(
            pool.poolType == PoolType.Loan ||
                pool.poolType == PoolType.ConstrainedLoan,
            _UNSUPPORTED_POOL_TYPE
        );
        require(
            transaction.transactionType == TransactionType.Borrow,
            'not a borrow transaction'
        );
        require(
            _amount <= transaction.amount,
            _AMOUNT_GREATER_THAN_TRANSACTION
        );

        uint256 interestToPay = transaction.pendingInterest.add(
            interestSinceLastUpdate(_pid, msg.sender)
        );

        transaction.pendingInterest = _ZERO;

        if (interestToPay > _ZERO) {
            pool.funds.balance = pool.funds.balance.add(interestToPay);
        }

        transaction.amount = transaction.amount.sub(_amount);

        transaction.time = block.timestamp;

        pool.funds.loanedBalance = pool.funds.loanedBalance.sub(_amount);

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.reserve),
            _amount
        );

        if (interestToPay > _ZERO) {
            pool.tokenInfo.token.safeTransferFrom(
                msg.sender,
                address(pool.tokenInfo.reserve),
                interestToPay
            );
        }

        _removeUserIfStakeIsEmpty(_pid);

        emit Repaid(msg.sender, _pid, _amount);
    }

    function handleCollateralTokenTransfer(
        uint256 _pid,
        address from,
        address to,
        uint256 amount
    ) external {
        require(_isACollateralToken[msg.sender], 'Unauthorized!');

        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage sender = userInfo[_pid][from];
        UserInfo storage recepient = userInfo[_pid][to];

        require(
            recepient.transaction.amount == _ZERO ||
                recepient.transaction.transactionType ==
                TransactionType.Staking,
            'Recepient is a borrower'
        );

        recepient.transaction.transactionType = TransactionType.Staking;

        if (recepient.transaction.time == _ZERO) {
            recepient.transaction.time = sender.transaction.time;
        }

        sender.transaction.amount = sender.transaction.amount.sub(amount);

        recepient.transaction.amount = recepient.transaction.amount.add(amount);

        emit StakeTransferred(_pid, from, to, amount);
    }

    function getUserInfo(
        uint256 _pid,
        address _user
    ) external view returns (UserInfo memory) {
        return userInfo[_pid][_user];
    }

    function getPoolInfo(
        uint256 _from,
        uint256 _to
    ) external view returns (PoolInfo[] memory) {
        PoolInfo[] memory tPoolInfo = new PoolInfo[](_to.sub(_from).add(_ONE));

        uint256 j = _ZERO;

        for (uint256 i = _from; i <= _to; i++) {
            tPoolInfo[j++] = _poolInfo[i];
        }

        return tPoolInfo;
    }

    function getUserStakes(
        uint256 _pid,
        address _user
    ) external view returns (Transaction memory) {
        return userInfo[_pid][_user].transaction;
    }

    function getPoolInfo(uint256 _pid) external view returns (PoolInfo memory) {
        return _poolInfo[_pid];
    }

    // End Mange Pools
    function totalPools() external view returns (uint256) {
        return _poolInfo.length;
    }

    function myTotalUnsettledInterest(
        address userAddress,
        uint256 _pid
    ) external view returns (uint256) {
        UserInfo memory user = userInfo[_pid][userAddress];
        Transaction memory transaction = user.transaction;
        PoolInfo memory pool = _poolInfo[_pid];

        if (transaction.transactionType == TransactionType.Borrow) {
            return
                transaction.pendingInterest.add(
                    interestSinceLastUpdate(_pid, userAddress)
                );
        }

        if (pool.poolType == PoolType.Loan) {
            return
                (
                    transaction.amount.mul(pool.funds.balance).div(
                        pool.tokenInfo.reserve.totalSupply()
                    )
                ).sub(transaction.amount);
        } else {
            return interestSinceLastUpdate(_pid, userAddress);
        }
    }

    /**
     * @dev Should be checked before updating transaction `amount` and `time`
     */
    function interestSinceLastUpdate(
        uint256 _pid,
        address userAddress
    ) public view returns (uint256) {
        PoolInfo memory pool = _poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][userAddress];
        Transaction memory transaction = user.transaction;

        if (transaction.amount == _ZERO || pool.funds.balance == _ZERO)
            return _ZERO;

        if (transaction.transactionType == TransactionType.Borrow) {
            uint256 interest;

            if (pool.poolType == PoolType.Loan) {
                uint256 duration = block.timestamp.sub(transaction.time);

                interest = _calculateInterest(
                    _pid,
                    transaction.amount,
                    duration
                );
            } else if (pool.poolType == PoolType.ConstrainedLoan) {
                interest = (
                    transaction
                        .amount
                        .mul(pool.tokenInfo.reserve.totalSupply())
                        .div(pool.funds.balance)
                ).sub(transaction.amount);
            }

            return interest;
        } else {
            if (
                (pool.poolType == PoolType.Staking ||
                    pool.poolType == PoolType.ConstrainedLoan) &&
                !pool.interestPayoutsStarted
            ) return _ZERO;

            uint256 duration;

            uint256 timeSinceLastTransaction = block.timestamp.sub(
                transaction.time
            );

            if (pool.poolType == PoolType.Loan) {
                duration = timeSinceLastTransaction;
            } else {
                uint256 timeSinceDepositsEnd = block.timestamp.sub(
                    pool.depositLimiters.endTime
                );

                if (timeSinceLastTransaction < timeSinceDepositsEnd) {
                    duration = timeSinceLastTransaction;

                    if (
                        duration.add(transaction.paidOutForDuration) >
                        pool.depositLimiters.duration
                    ) {
                        duration = pool.depositLimiters.duration.sub(
                            transaction.paidOutForDuration
                        );
                    }
                } else {
                    duration = timeSinceDepositsEnd;

                    if (duration > pool.depositLimiters.duration) {
                        duration = pool.depositLimiters.duration;
                    }
                }
            }

            uint256 reward = _calculateInterest(
                _pid,
                transaction.amount,
                duration
            );

            return reward;
        }
    }

    function _removeUserIfStakeIsEmpty(uint256 _pid) private {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction storage transaction = user.transaction;

        if (transaction.amount == _ZERO) {
            user.isAPoolUser = false;
            pool.uniqueUsers = pool.uniqueUsers.sub(_ONE);
        }
    }

    function _addUniqueUser(uint256 _pid) private {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (!user.isAPoolUser) {
            user.isAPoolUser = true;
            pool.uniqueUsers = pool.uniqueUsers.add(_ONE);
        }
    }

    function _transferRewards(
        uint256 _pid,
        uint256 _amount,
        uint256 _duration
    ) private {
        PoolInfo storage pool = _poolInfo[_pid];
        Transaction storage transaction = userInfo[_pid][msg.sender]
            .transaction;

        uint256 rewardsToSend = _calculateInterest(_pid, _amount, _duration);

        transaction.paidOutForDuration = transaction.paidOutForDuration.add(
            _duration
        );

        if (rewardsToSend > _ZERO) {
            pool.funds.balance = pool.funds.balance.sub(rewardsToSend);

            _resetReserveAllowanceIfRequired(
                pool.tokenInfo.reserve,
                pool.tokenInfo.token,
                _amount
            );

            pool.tokenInfo.token.safeTransferFrom(
                address(pool.tokenInfo.reserve),
                msg.sender,
                rewardsToSend
            );

            emit RewardHarvested(msg.sender, _pid, rewardsToSend);
        }
    }

    function _resetReserveAllowanceIfRequired(
        IReserve _reserve,
        IERC20Metadata _token,
        uint256 _amount
    ) private {
        uint256 allowance = _token.allowance(address(_reserve), address(this));

        if (allowance < _amount) {
            _reserve.resetAllowance();
        }
    }

    function _calculateInterest(
        uint256 _pid,
        uint256 _amount,
        uint256 _duration
    ) private view returns (uint256) {
        PoolInfo memory pool = _poolInfo[_pid];

        uint256 utilisation;

        if (
            pool.poolType == PoolType.Staking ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            // Ignore Utilisation (use 100%)
            utilisation = _ONE_HUNDRED.mul(_PERCENTAGE_PRECISION);
        } else if (pool.poolType == PoolType.Loan) {
            // Calculate interest according to utilisation
            utilisation = _getPoolUtilisation(_pid);
        }

        return
            (_amount.mul(pool.apy).mul(utilisation).mul(_duration)).div(
                _ONE_YEAR
                    .mul(_ONE_HUNDRED)
                    .mul(_PERCENTAGE_PRECISION)
                    .mul(_ONE_HUNDRED)
                    .mul(_PERCENTAGE_PRECISION)
            );
    }

    /**
     * @dev Ratio of loaned balance v.s. pool balance in percent.
     * Make sure that `_PERCENTAGE_PRECISION` is utilised while using the result
     */
    function _getPoolUtilisation(uint256 _pid) private view returns (uint256) {
        PoolInfo memory pool = _poolInfo[_pid];

        uint256 utilisation = _calculatePercentage(
            pool.funds.loanedBalance,
            pool.funds.balance
        );

        return utilisation;
    }

    function _calculatePercentage(
        uint256 _value,
        uint256 _of
    ) private pure returns (uint256) {
        if (_of == _ZERO) return _ZERO;

        uint256 percentage = _value
            .mul(_ONE_HUNDRED)
            .mul(_PERCENTAGE_PRECISION)
            .div(_of);

        return percentage;
    }
}
