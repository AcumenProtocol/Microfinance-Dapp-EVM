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
        uint8 _tokenDecimals
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

    IReserveDeployer private immutable reserveDeployer;

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
        TransactionType transactionType; // The type of transaction
        uint256 amount; // The amount involved
        uint256 time; // Transaction (updated) time
        uint256 paidOut; // Paid out rewards
        uint256 paidOutForQuarters; // Count of quarters paid
    }

    struct TokenInfo {
        IERC20Metadata token;
        IReserve reserve;
        uint8 decimals;
        string name;
        string symbol;
    }

    struct DepositLimiters {
        uint256 duration; // Lockup period
        uint256 startTime; // Deposits Start Time, applicable for poolType Staking
        uint256 endTime; // Deposits End Time, applicable for poolType Staking
        uint256 limitPerUser; // Limit Per Deposit Transaction
        uint256 capacity; // The pool capacity
        uint256 maxUtilisation; // Applicable for poolType Loan
    }

    struct Funds {
        uint256 balance;
        uint256 loanedBalance;
    }

    struct UserInfo {
        bool isAPoolUser;
        bool isWhitelisted;
        Transaction[] transactions;
        uint256 totalAmountStaked;
        uint256 totalAmountBorrowed;
    }

    struct PoolInfo {
        string poolName;
        PoolType poolType;
        uint256 APY; // "Max. APY" in case of poolType Loan
        bool paused;
        bool quarterlyPayout; // Applicable for poolType Staking
        bool interestPayoutsStarted; // Applicable for poolType Staking
        uint256 uniqueUsers;
        TokenInfo tokenInfo;
        Funds funds;
        DepositLimiters depositLimiters;
    }
    PoolInfo[] private poolInfoPrivate;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Values used throughout the contract
    string private INTEREST_PAYOUT_NOT_STARTED = 'Interest payout not started';
    string private UNSUPPORTED_POOL_TYPE = 'unsupported pool for this action';
    string private AMOUNT_GREATER_THAN_TRANSACTION = 'amount greater than the transaction amount';
    uint256 private oneHundred = 100;
    uint256 private percentagePrecision = 1 ether;
    uint256 private oneYear = 365 days;
    uint256 private oneQuarter = 90 days;
    uint256 private zero = 0;
    uint256 private one = 1;

    constructor(IReserveDeployer _reserveDeployer, address _owner) {
        reserveDeployer = _reserveDeployer;
        _transferOwnership(_owner);
    }

    // Manage Pools
    function setPoolPaused(uint256 _pid, bool _flag) external onlyOwner {
        poolInfoPrivate[_pid].paused = _flag;
        emit PoolPaused(_pid, _flag);
    }

    function startInterest(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfoPrivate[_pid];

        require(
            pool.poolType == PoolType.Staking ||
                pool.poolType == PoolType.ConstrainedLoan,
            UNSUPPORTED_POOL_TYPE
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

    // End Mange Pools

    function totalPools() public view returns (uint256) {
        return poolInfoPrivate.length;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory) {
        return poolInfoPrivate[_pid];
    }

    /*
    * @dev Deposits the chosen _amount with the specified constraints
    */
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction[] storage transactions = user.transactions;

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

        require(
            user.totalAmountBorrowed == zero,
            'Should repay all borrowed before staking'
        );
        require(!pool.paused, 'Pool Paused');
        require(
            _amount <= pool.depositLimiters.limitPerUser,
            'amount exceeds limit per transaction'
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

        user.totalAmountStaked = user.totalAmountStaked.add(_amount);
        transactions.push(
            Transaction({
                transactionType: TransactionType.Staking,
                amount: _amount,
                time: block.timestamp,
                paidOut: zero,
                paidOutForQuarters: zero
            })
        );

        pool.funds.balance = pool.funds.balance.add(_amount);

        addUniqueUser(_pid);

        pool.tokenInfo.reserve.mintCollateralToken(msg.sender, _amount);

        emit Deposited(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _index, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction storage transaction = user.transactions[_index];

        require(
            transaction.transactionType == TransactionType.Staking,
            'not staked'
        );
        require(_amount <= transaction.amount, AMOUNT_GREATER_THAN_TRANSACTION);

        if (
            pool.poolType == PoolType.Staking ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            require(pool.interestPayoutsStarted, INTEREST_PAYOUT_NOT_STARTED);
            require(
                block.timestamp >=
                    pool.depositLimiters.endTime.add(
                        pool.depositLimiters.duration
                    ),
                'withdrawing too early'
            );
        }
        
        if (pool.poolType == PoolType.ConstrainedLoan || pool.poolType == PoolType.Loan) {
            require(
                pool.funds.balance >= pool.funds.loanedBalance.add(_amount),
                'amount is currently utilised'
            );

            uint256 projectedUtilisation = calculatePercentage(
                pool.funds.loanedBalance,
                pool.funds.balance.sub(_amount)
            );

            require(
                projectedUtilisation <=
                    pool.depositLimiters.maxUtilisation.mul(
                        percentagePrecision
                    ),
                'pool utilisation will max out if withdrawn'
            );
        }

        // Update user states
        transaction.amount = transaction.amount.sub(_amount);
        user.totalAmountStaked = user.totalAmountStaked.sub(_amount);

        uint256 originalAmount = _amount;

        if (
            pool.poolType == PoolType.Staking ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            // Send rewards according to APY

            uint256 timeSinceDepositsEnd = block.timestamp.sub(pool.depositLimiters.endTime);
            uint256 timeSinceLastTransaction = block.timestamp.sub(transaction.time);
            
            uint256 duration;

            if(timeSinceLastTransaction < timeSinceDepositsEnd) {
                duration = timeSinceLastTransaction;
            } else {
                duration = timeSinceDepositsEnd;
            }

            if (duration > pool.depositLimiters.duration) {
                duration = pool.depositLimiters.duration;
            }

            transferRewards(_pid, _index, _amount, duration);
        } else if (pool.poolType == PoolType.Loan) {
            // Send rewards according to the current interest paid by the borrowers
            _amount = _amount.mul(pool.funds.balance).div(
                pool.tokenInfo.reserve.totalSupply()
            );

            if (_amount > originalAmount) {
                uint256 rewards = _amount.sub(originalAmount);
                transaction.paidOut = transaction.paidOut.add(rewards);
            }
        }

        transaction.time = block.timestamp;

        // Update global states
        pool.funds.balance = pool.funds.balance.sub(_amount);

        deleteStakeIfEmpty(_pid, _index);

        pool.tokenInfo.reserve.burnCollateralToken(
            msg.sender,
            originalAmount
        );

        resetReserveAllowanceIfRequired(pool.tokenInfo.reserve, pool.tokenInfo.token, _amount);
       
        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.reserve),
            msg.sender,
            _amount
        );

        emit Withdrawn(msg.sender, _pid, _amount);
    }

    function borrow(uint256 _pid, uint256 _amount) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfoPrivate[_pid];
        Transaction[] storage transactions = userInfo[_pid][msg.sender]
            .transactions;
        require(
            user.totalAmountStaked == zero,
            'Should withdraw all staked before borrowing'
        );
        require(
            pool.poolType == PoolType.Loan ||
                pool.poolType == PoolType.ConstrainedLoan,
            UNSUPPORTED_POOL_TYPE
        );
        require(user.isWhitelisted, 'Only whitelisted can borrow');
        require(!pool.paused, 'Pool paused');
        require(pool.funds.balance > zero, 'Nothing deposited');

        uint256 projectedUtilisation = calculatePercentage(
            pool.funds.loanedBalance.add(_amount),
            pool.funds.balance
        );

        require(
            projectedUtilisation <=
                pool.depositLimiters.maxUtilisation.mul(percentagePrecision),
            'utilisation will max out if borrowed'
        );

        // Update global states
        pool.funds.loanedBalance = pool.funds.loanedBalance.add(_amount);

        // Update user states
        user.totalAmountBorrowed = user.totalAmountBorrowed.add(_amount);

        resetReserveAllowanceIfRequired(
            pool.tokenInfo.reserve,
            pool.tokenInfo.token,
            _amount
        );

        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.reserve),
            msg.sender,
            _amount
        );

        transactions.push(
            Transaction({
                transactionType: TransactionType.Borrow,
                amount: _amount,
                time: block.timestamp,
                paidOut: zero,
                paidOutForQuarters: zero
            })
        );

        addUniqueUser(_pid);

        emit Borrowed(msg.sender, _pid, _amount);
    }

    function repay(uint256 _pid, uint256 _index, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction storage transaction = user.transactions[_index];

        require(
            pool.poolType == PoolType.Loan ||
                pool.poolType == PoolType.ConstrainedLoan,
            UNSUPPORTED_POOL_TYPE
        );
        require(
            transaction.transactionType == TransactionType.Borrow,
            'not a borrow transaction'
        );
        require(_amount <= transaction.amount, AMOUNT_GREATER_THAN_TRANSACTION);

        uint256 interest;

        if (pool.poolType == PoolType.Loan) {
            uint256 duration = block.timestamp.sub(transaction.time);

            interest = calculateInterest(
                _pid,
                _amount,
                duration
            );
        } else if (pool.poolType == PoolType.ConstrainedLoan) {
            interest = (_amount.mul(pool.tokenInfo.reserve.totalSupply()).div(
                pool.funds.balance)).sub(_amount);
        }

        if (interest > zero) {
            pool.funds.balance = pool.funds.balance.add(interest);
        }

        transaction.amount = transaction.amount.sub(_amount);

        transaction.time = block.timestamp;

        user.totalAmountBorrowed = user.totalAmountBorrowed.sub(_amount);

        pool.funds.loanedBalance = pool.funds.loanedBalance.sub(_amount);

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.reserve),
            _amount
        );

        if (interest > zero) {
            pool.tokenInfo.token.safeTransferFrom(
                msg.sender,
                address(pool.tokenInfo.reserve),
                interest
            );
        }

        emit Repaid(msg.sender, _pid, _amount);

        deleteStakeIfEmpty(_pid, _index);
    }

    function deleteStakeIfEmpty(uint256 _pid, uint256 _index) private {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction[] storage transactions = user.transactions;

        if (transactions[_index].amount == zero) {
            if (_index != transactions.length.sub(one))
                transactions[_index] = transactions[
                    transactions.length.sub(one)
                ];

            transactions.pop();
        }

        if (transactions.length == zero) {
            user.isAPoolUser = false;
            pool.uniqueUsers = pool.uniqueUsers.sub(one);
        }
    }

    function addUniqueUser(uint256 _pid) private {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (!user.isAPoolUser) {
            user.isAPoolUser = true;
            pool.uniqueUsers = pool.uniqueUsers.add(one);
        }
    }

    function calculatePercentage(
        uint256 _value,
        uint256 _of
    ) private view returns (uint256) {
        if (_of == zero) return zero;

        uint256 percentage = _value
            .mul(oneHundred)
            .mul(percentagePrecision)
            .div(_of);

        return percentage;
    }

    function transferRewards(
        uint256 _pid,
        uint256 _index,
        uint256 _amount,
        uint256 _duration
    ) private returns (uint256 claimedRewards) {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        Transaction storage transaction = userInfo[_pid][msg.sender]
            .transactions[_index];

        uint256 reward = calculateInterest(
            _pid,
            _amount,
            _duration
        );

        if (reward > zero) {
            transaction.paidOut = transaction.paidOut.add(reward);
            pool.funds.balance = pool.funds.balance.sub(reward);

            resetReserveAllowanceIfRequired(
                pool.tokenInfo.reserve,
                pool.tokenInfo.token,
                _amount 
            );

            pool.tokenInfo.token.safeTransferFrom(
                address(pool.tokenInfo.reserve),
                msg.sender,
                reward
            );

            emit RewardHarvested(msg.sender, _pid, reward);
        }

        return reward;
    }

    function calculateInterest(
        uint256 _pid,
        uint256 _amount,
        uint256 _duration
    ) private view returns (uint256) {
        PoolInfo memory pool = poolInfoPrivate[_pid];

        uint256 utilisation;

        if (
            pool.poolType == PoolType.Staking ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            // Ignore Utilisation (use 100%)
            utilisation = oneHundred.mul(percentagePrecision);
        } else if (pool.poolType == PoolType.Loan) {
            utilisation = getPoolUtilisation(_pid);
        }

        return
            (_amount.mul(pool.APY).mul(utilisation).mul(_duration)).div(
                oneHundred.mul(oneHundred).mul(oneYear).mul(percentagePrecision)
            );
    }

    /*
     * @dev Ratio of loaned balance v.s. pool balance in percent.
     * Make sure that `percentagePrecision` is utilised while using its result
     */
    function getPoolUtilisation(uint256 _pid) private view returns (uint256) {
        PoolInfo memory pool = poolInfoPrivate[_pid];

        uint256 utilisation = calculatePercentage(
            pool.funds.loanedBalance,
            pool.funds.balance
        );

        return utilisation;
    }

    function getUserInfo(
        uint256 _pid,
        address _user
    ) external view returns (UserInfo memory) {
        return userInfo[_pid][_user];
    }


    /* 
     * @dev Should allow users to withdraw rewards quarterly without withdrawing 
     * any amount from their stake if `quarterlyPayout` is enabled for the pool
     */
    function claimQuarterlyPayout(uint256 _pid, uint256 _index) external {
        PoolInfo memory pool = poolInfoPrivate[_pid];
        Transaction storage transaction = userInfo[_pid][msg.sender]
            .transactions[_index];

        require(
            pool.poolType == PoolType.Staking ||
                pool.poolType == PoolType.ConstrainedLoan,
            'quarterlyPayout not valid for poolType Loan'
        );
        require(pool.quarterlyPayout, 'quarterlyPayout disabled for this pool');

        require(
            block.timestamp > pool.depositLimiters.endTime &&
                pool.interestPayoutsStarted,
            INTEREST_PAYOUT_NOT_STARTED
        );

        uint256 timeSinceDepositsEnd = block.timestamp.sub(pool.depositLimiters.endTime);
        uint256 timeSinceLastTransaction = block.timestamp.sub(transaction.time);

        uint256 quartersPassedSinceDepositsEnd = timeSinceDepositsEnd.div(oneQuarter);
        require(quartersPassedSinceDepositsEnd > zero, 'too early');

        require(transaction.paidOutForQuarters < quartersPassedSinceDepositsEnd, 'already withdrawn');
        transaction.paidOutForQuarters = quartersPassedSinceDepositsEnd;

        uint256 duration;

        if(timeSinceLastTransaction < timeSinceDepositsEnd) {
            // Use the last transaction time
            duration = timeSinceLastTransaction;
            // Update the transaction time, since the rewards till this duration will be paid
            transaction.time = block.timestamp;
        } else {
            // Use the duration according to the count of full quarters passed
            duration = quartersPassedSinceDepositsEnd.mul(oneQuarter);
            // Update the transaction time till the paid duration
            transaction.time = pool.depositLimiters.endTime.add(quartersPassedSinceDepositsEnd.mul(oneQuarter));
        }

        if (duration > pool.depositLimiters.duration) {
            duration = pool.depositLimiters.duration;
        }
        
        transferRewards(_pid, _index, transaction.amount, duration);
    }

    function whitelist(
        uint256 _pid,
        address _user,
        bool _status
    ) external onlyOwner {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        require(
            pool.poolType == PoolType.Loan ||
                pool.poolType == PoolType.ConstrainedLoan,
            UNSUPPORTED_POOL_TYPE
        );

        user.isWhitelisted = _status;

        emit Whitelisted(_user, _pid, _status);
    }

    function createPool(PoolInfo memory _poolInfo) external onlyOwner {
        if (
            _poolInfo.poolType == PoolType.Staking ||
            _poolInfo.poolType == PoolType.ConstrainedLoan
        ) {
            _poolInfo.depositLimiters.startTime =  
                _poolInfo.depositLimiters.startTime < block.timestamp ? block.timestamp 
                : _poolInfo.depositLimiters.startTime;

            require(
                _poolInfo.depositLimiters.startTime <
                    _poolInfo.depositLimiters.endTime,
                'end time should be after start time'
            );
        } else {
            _poolInfo.depositLimiters.startTime = zero;
            _poolInfo.depositLimiters.endTime = zero;
        }

        _poolInfo.funds.balance = zero;
        _poolInfo.funds.loanedBalance = zero;
        _poolInfo.uniqueUsers = zero;
        _poolInfo.interestPayoutsStarted = false;

        // Store token info
        _poolInfo.tokenInfo.decimals = _poolInfo.tokenInfo.token.decimals();
        _poolInfo.tokenInfo.name = _poolInfo.tokenInfo.token.name();
        _poolInfo.tokenInfo.symbol = _poolInfo.tokenInfo.token.symbol();

        if (
            _poolInfo.poolType == PoolType.Loan ||
            _poolInfo.poolType == PoolType.ConstrainedLoan
        ) {
            require(
                _poolInfo.depositLimiters.maxUtilisation <= oneHundred,
                'Utilisation can be maximum 100%'
            );
        } else {
            _poolInfo.depositLimiters.maxUtilisation = oneHundred;
        }

        address _reserve = reserveDeployer.createReserve(
            address(this),
            address(_poolInfo.tokenInfo.token),
            _poolInfo.tokenInfo.decimals
        );

        _poolInfo.tokenInfo.reserve = IReserve(_reserve);

        poolInfoPrivate.push(_poolInfo);
    }

    function editPool(
        uint256 _pid,
        PoolInfo memory _newPoolInfo
    ) external onlyOwner {
        PoolInfo memory pool = poolInfoPrivate[_pid];

        // Perserve some info
        _newPoolInfo.funds.balance = pool.funds.balance;
        _newPoolInfo.funds.loanedBalance = pool.funds.loanedBalance;
        _newPoolInfo.uniqueUsers = pool.uniqueUsers;
        _newPoolInfo.tokenInfo.token = pool.tokenInfo.token;
        _newPoolInfo.tokenInfo.reserve = pool.tokenInfo.reserve;
        _newPoolInfo.poolType = pool.poolType;

        if (
            pool.poolType == PoolType.Loan ||
            pool.poolType == PoolType.ConstrainedLoan
        ) {
            // Check utilisation
            require(
                _newPoolInfo.depositLimiters.maxUtilisation <= oneHundred,
                'maxUtilisation cannot exceed 100%'
            );

            uint256 currentUtilisation = getPoolUtilisation(_pid);

            require(
                _newPoolInfo.depositLimiters.maxUtilisation.mul(
                    percentagePrecision
                ) >= currentUtilisation,
                'should not set maxUtilisation less than current utilisation'
            );
        } else {
            _newPoolInfo.depositLimiters.maxUtilisation = oneHundred;
        }

        // Assign new values
        poolInfoPrivate[_pid] = _newPoolInfo;
    }

    function getPoolInfo(
        uint256 _from,
        uint256 _to
    ) external view returns (PoolInfo[] memory) {
        PoolInfo[] memory tPoolInfo = new PoolInfo[](_to.sub(_from).add(one));

        uint256 j = zero;

        for (uint256 i = _from; i <= _to; i++) {
            tPoolInfo[j++] = poolInfoPrivate[i];
        }

        return tPoolInfo;
    }

    function totalTransactionsOfUser(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        Transaction[] memory transactions = userInfo[_pid][_user].transactions;

        return transactions.length;
    }

    function getUserStakes(
        uint256 _pid,
        address _user,
        uint256 _from,
        uint256 _to
    ) external view returns (Transaction[] memory) {
        Transaction[] memory tUserInfo = new Transaction[](
            _to.sub(_from).add(one)
        );
        Transaction[] memory transactions = userInfo[_pid][_user].transactions;

        uint256 j = zero;

        for (uint256 i = _from; i <= _to; i++) {
            tUserInfo[j++] = transactions[i];
        }

        return tUserInfo;
    }

    function resetReserveAllowanceIfRequired(
        IReserve _reserve,
        IERC20Metadata _token,
        uint256 _amount
    ) private {
        uint256 allowance = _token.allowance(address(_reserve), address(this));
        
        if(allowance < _amount) {
            _reserve.resetAllowance();
        }
    }

    // Events
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    event RewardHarvested(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event PoolPaused(uint256 indexed _pid, bool _flag);

    event Whitelisted(address indexed user, uint256 indexed pid, bool status);

    event Borrowed(address indexed user, uint256 indexed pid, uint256 amount);
    event Repaid(address indexed user, uint256 indexed pid, uint256 amount);
}
