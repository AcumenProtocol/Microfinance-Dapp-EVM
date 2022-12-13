// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );
        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), 'Address: static call to non-contract');
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), 'Address: delegate call to non-contract');
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                'SafeBEP20: decreased allowance below zero'
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            'SafeBEP20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                'SafeBEP20: BEP20 operation did not succeed'
            );
        }
    }
}

interface ISCTDeployer {
    function createToken(
        address _stakerContract,
        address _tokenContract,
        uint8 _tokenDecimals
    ) external returns (address);
}

interface ICollateralToken {
    function recoverEther(address _to, uint256 _amount) external returns (bool);
}

contract Staking is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    ISCTDeployer collateralTokenDeployer;

    enum PoolType {
        Staking,
        Loan
    }

    enum TransactionType {
        Staking,
        Borrow
    }

    struct UserInfo {
        TransactionType transactionType;
        uint256 amount;
        uint256 time;
        uint256 paidOut;
    }

    struct TokenInfo {
        IBEP20 token;
        IBEP20 collateralToken;
        uint256 decimals;
        string name;
        string symbol;
    }

    struct DepositLimiters {
        uint256 duration;
        uint256 startTime; // Deposits Start Time
        uint256 endTime; // Deposits End Time
        uint256 limitPerUser; // Limit Per Deposit Transaction
        uint256 capacity;
        uint256 maxUtilisation;
    }

    struct Funds {
        uint256 balance;
        uint256 loanedBalance;
    }

    struct PoolInfo {
        string poolName;
        PoolType poolType;
        uint256 APY; // "Max. APY" in case of poolType Loan
        bool paused;
        bool quarterlyPayout;
        bool interestPayoutsStarted; // Applicable for poolType Staking
        uint256 uniqueUsers;
        TokenInfo tokenInfo;
        Funds funds;
        DepositLimiters depositLimiters;
    }
    PoolInfo[] private poolInfoPrivate;

    string INTEREST_PAYOUT_NOT_STARTED = 'Interest payout not started';

    mapping(uint256 => mapping(address => bool)) public isAPoolUser;
    mapping(uint256 => mapping(address => bool)) public isWhitelisted;
    mapping(uint256 => mapping(address => UserInfo[])) public userInfo;
    mapping(uint256 => mapping(address => uint256))
        public totalUserAmountStaked;
    mapping(uint256 => mapping(address => uint256))
        public totalUserAmountBorrowed;

    constructor() {
        collateralTokenDeployer = ISCTDeployer(
            0x34035518F24385509C31234d0660cAAB7ffB8b99
        );
    }

    // Manage Pools
    function setPoolPaused(uint256 _pid, bool _flag) external onlyOwner {
        poolInfoPrivate[_pid].paused = _flag;
    }

    function startInterest(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfoPrivate[_pid];

        require(
            !pool.interestPayoutsStarted,
            'Interest payouts already started'
        );

        // Enable payouts
        pool.interestPayoutsStarted = true;
        // Interest will be calculated from now
        pool.depositLimiters.endTime = block.timestamp;
    }

    function setCollateralTokenDeployer(
        ISCTDeployer _newDeployer
    ) external onlyOwner {
        collateralTokenDeployer = _newDeployer;
    }

    // End Mange Pools

    function totalPools() public view returns (uint256) {
        return poolInfoPrivate.length;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory) {
        PoolInfo memory tPoolInfo;

        tPoolInfo = poolInfoPrivate[_pid];

        tPoolInfo.tokenInfo.decimals = tPoolInfo.tokenInfo.token.decimals();
        tPoolInfo.tokenInfo.name = tPoolInfo.tokenInfo.token.name();
        tPoolInfo.tokenInfo.symbol = tPoolInfo.tokenInfo.token.symbol();

        return tPoolInfo;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo[] storage transaction = userInfo[_pid][msg.sender];
        require(
            totalUserAmountBorrowed[_pid][msg.sender] == 0,
            'Should repay all borrowed before staking'
        );

        require(!pool.paused, 'Pool Paused');
        if (pool.poolType == PoolType.Staking) {
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
            _amount <= pool.depositLimiters.limitPerUser,
            'amount exceeds limit per transaction'
        );
        require(
            pool.funds.balance + _amount <= pool.depositLimiters.capacity,
            'pool capacity reached'
        );

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.collateralToken),
            _amount
        );

        totalUserAmountStaked[_pid][msg.sender] = totalUserAmountStaked[_pid][
            msg.sender
        ].add(_amount);

        pool.funds.balance = pool.funds.balance.add(_amount);

        transaction.push(
            UserInfo({
                transactionType: TransactionType.Staking,
                amount: _amount,
                time: block.timestamp,
                paidOut: 0
            })
        );

        addUniqueUser(_pid);

        pool.tokenInfo.collateralToken.mint(msg.sender, _amount);

        emit Deposited(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _index, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage transaction = userInfo[_pid][msg.sender][_index];

        require(
            transaction.transactionType == TransactionType.Staking,
            'not staked'
        );
        require(_amount <= transaction.amount, 'amount greater than available');

        if (pool.poolType == PoolType.Staking) {
            // Check if the user is withdrawing early
            require(pool.interestPayoutsStarted, INTEREST_PAYOUT_NOT_STARTED);
            require(
                block.timestamp >=
                    pool.depositLimiters.endTime +
                        pool.depositLimiters.duration,
                'withdrawing too early'
            );
        } else {
            require(
                pool.funds.balance >= pool.funds.loanedBalance.add(_amount),
                'amount is currently utilised'
            );

            (
                uint256 projectedUtilisation,
                uint256 precision
            ) = calculatePercentage(
                    pool.funds.loanedBalance,
                    pool.funds.balance.sub(_amount)
                );

            require(
                projectedUtilisation <=
                    pool.depositLimiters.maxUtilisation.mul(precision),
                'pool utilisation will max out if withdrawn'
            );
        }

        // Update user states
        transaction.amount = transaction.amount.sub(_amount);
        transaction.time = block.timestamp;
        totalUserAmountStaked[_pid][msg.sender] = totalUserAmountStaked[_pid][
            msg.sender
        ].sub(_amount);

        uint256 _originalAmount = _amount;

        if (pool.poolType == PoolType.Staking) {
            // Send rewards according to APY
            uint256 _duration = block.timestamp.sub(
                pool.depositLimiters.endTime
            );

            if (_duration > pool.depositLimiters.duration) {
                _duration = pool.depositLimiters.duration;
            }

            transferRewards(_pid, _index, _amount, _duration);
        } else if (pool.poolType == PoolType.Loan) {
            // Add rewards to _amount with the ratio according to current interest paid
            _amount = _amount.mul(pool.funds.balance).div(
                pool.tokenInfo.collateralToken.totalSupply()
            );
        }

        // Update global states
        pool.funds.balance = pool.funds.balance.sub(_amount);

        deleteStakeIfEmpty(_pid, _index);

        pool.tokenInfo.collateralToken.burn(msg.sender, _originalAmount);
        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.collateralToken),
            msg.sender,
            _amount
        );

        emit Withdrawn(msg.sender, _pid, _amount);
    }

    function deleteStakeIfEmpty(uint256 _pid, uint256 _index) private {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo[] storage transactions = userInfo[_pid][msg.sender];

        if (transactions[_index].amount == 0) {
            transactions[_index] = transactions[transactions.length - 1];
            transactions.pop();
        }

        if (transactions.length == 0) {
            isAPoolUser[_pid][msg.sender] = false;
            pool.uniqueUsers = pool.uniqueUsers.sub(1);
        }
    }

    function addUniqueUser(uint256 _pid) private {
        PoolInfo storage pool = poolInfoPrivate[_pid];

        if (!isAPoolUser[_pid][msg.sender]) {
            pool.uniqueUsers = pool.uniqueUsers.add(1);
        }

        isAPoolUser[_pid][msg.sender] = true;
    }

    function calculatePercentage(
        uint256 _value,
        uint256 _of
    ) public pure returns (uint256, uint256) {
        uint256 precision = 1 ether;

        // Special condition for division by zero
        if (_of == 0) return (0, precision);

        uint256 percentage = _value.mul(100).mul(precision).div(_of);

        return (percentage, precision);
    }

    function transferRewards(
        uint256 _pid,
        uint256 _index,
        uint256 _amount,
        uint256 _duration
    ) private returns (uint256 claimedRewards) {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage transaction = userInfo[_pid][msg.sender][_index];

        require(_amount <= transaction.amount, 'amount greater than available');

        // Calculate rewards according to APY
        uint256 reward = calculateInterest(
            msg.sender,
            _pid,
            _index,
            _amount,
            _duration
        );

        if (reward > transaction.paidOut) {
            reward = reward.sub(transaction.paidOut);
        } else {
            reward = uint256(0);
        }

        transaction.paidOut = transaction.paidOut.add(reward);
        pool.funds.balance = pool.funds.balance.sub(reward);

        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.collateralToken),
            msg.sender,
            reward
        );

        emit RewardHarvested(msg.sender, _pid, reward);

        return reward;
    }

    function borrow(uint256 _pid, uint256 _amount) public {
        require(isWhitelisted[_pid][msg.sender], 'Only whitelisted can borrow');
        require(
            totalUserAmountStaked[_pid][msg.sender] == 0,
            'Should withdraw all staked before borrowing'
        );

        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo[] storage transactions = userInfo[_pid][msg.sender];

        require(pool.poolType == PoolType.Loan, 'no loans from here');

        require(!pool.paused, 'Pool Paused');

        require(pool.funds.balance > 0, 'Nothing deposited');

        (uint256 projectedUtilisation, uint256 precision) = calculatePercentage(
            pool.funds.loanedBalance.add(_amount),
            pool.funds.balance
        );

        require(
            projectedUtilisation <=
                pool.depositLimiters.maxUtilisation.mul(precision),
            'utilisation maxed out'
        );

        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.collateralToken),
            msg.sender,
            _amount
        );

        totalUserAmountBorrowed[_pid][msg.sender] = totalUserAmountBorrowed[
            _pid
        ][msg.sender].add(_amount);

        pool.funds.loanedBalance = pool.funds.loanedBalance.add(_amount);

        transactions.push(
            UserInfo({
                transactionType: TransactionType.Borrow,
                amount: _amount,
                time: block.timestamp,
                paidOut: 0
            })
        );

        addUniqueUser(_pid);

        emit Borrowed(msg.sender, _pid, _amount);
    }

    function repay(uint256 _pid, uint256 _index, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage transaction = userInfo[_pid][msg.sender][_index];

        require(pool.poolType == PoolType.Loan, 'nothing borrowed from here');
        require(
            transaction.transactionType == TransactionType.Borrow,
            'not borrowed'
        );
        require(_amount <= transaction.amount, 'amount greater than borrowed');

        uint256 _duration = block.timestamp.sub(transaction.time);

        // Calculate interest according to APY
        uint256 interest = calculateInterest(
            msg.sender,
            _pid,
            _index,
            _amount,
            _duration
        );

        pool.funds.balance = pool.funds.balance.add(interest);

        transaction.amount = transaction.amount.sub(_amount);
        transaction.time = block.timestamp;

        totalUserAmountBorrowed[_pid][msg.sender] = totalUserAmountBorrowed[
            _pid
        ][msg.sender].sub(_amount);

        pool.funds.loanedBalance = pool.funds.loanedBalance.sub(_amount);

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.collateralToken),
            _amount
        );

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.collateralToken),
            interest
        );

        emit Repaid(msg.sender, _pid, _amount);

        deleteStakeIfEmpty(_pid, _index);
    }

    function calculateInterest(
        address _user,
        uint256 _pid,
        uint256 _index,
        uint256 _amount,
        uint256 _duration
    ) public view returns (uint256) {
        PoolInfo memory pool = poolInfoPrivate[_pid];
        UserInfo memory transaction = userInfo[_pid][_user][_index];

        require(_amount <= transaction.amount, 'amount greater than available');

        if (pool.poolType == PoolType.Staking) {
            if (block.timestamp < pool.depositLimiters.endTime) {
                // No pay outs earlier than deposits end time for poolType Staking
                return 0;
            }
        }

        (uint256 utilisation, uint256 precision) = getPoolUtilisation(_pid);

        if (pool.poolType == PoolType.Staking) {
            // Ignore Utilisation for PoolType Staking (use 100%)
            utilisation = uint256(100).mul(precision);
        }

        // Context: APY is dependent on utilisation for poolType Loan. Max APY is reached on 100% utilisation
        return
            (_amount.mul(pool.APY).mul(utilisation).mul(_duration)).div(
                uint256(100).mul(uint256(100)).mul(uint256(365 days)).mul(
                    precision
                )
            );
    }

    function getPoolUtilisation(
        uint256 _pid
    ) public view returns (uint256, uint256) {
        PoolInfo memory pool = poolInfoPrivate[_pid];

        (uint256 utilisation, uint256 precision) = calculatePercentage(
            pool.funds.loanedBalance,
            pool.funds.balance
        );

        return (utilisation, precision);
    }

    function claimQuarterlyPayout(uint256 _pid, uint256 _index) external {
        PoolInfo memory pool = poolInfoPrivate[_pid];
        UserInfo memory transaction = userInfo[_pid][msg.sender][_index];

        require(
            pool.poolType == PoolType.Staking,
            'quarterlyPayout not valid for poolType Staking'
        );
        require(pool.quarterlyPayout, 'quarterlyPayout disabled for pool');

        require(
            block.timestamp > pool.depositLimiters.endTime &&
                pool.interestPayoutsStarted,
            INTEREST_PAYOUT_NOT_STARTED
        );

        uint256 _duration = block.timestamp - pool.depositLimiters.endTime;

        if (_duration > pool.depositLimiters.duration) {
            _duration = pool.depositLimiters.duration;
        }

        uint256 quartersPassed = (_duration).div(90 days);

        require(quartersPassed > 0, 'too early');

        _duration = quartersPassed.mul(90 days);

        transferRewards(_pid, _index, transaction.amount, _duration);
    }

    function whitelist(
        uint256 _pid,
        address _user,
        bool _status
    ) external onlyOwner {
        PoolInfo storage pool = poolInfoPrivate[_pid];

        require(pool.poolType == PoolType.Loan, 'no loans from here');

        isWhitelisted[_pid][_user] = _status;

        emit Whitelisted(_user, _pid, _status);
    }

    function createPool(PoolInfo memory _poolInfo) external onlyOwner {
        if (_poolInfo.poolType == PoolType.Staking) {
            require(
                _poolInfo.depositLimiters.startTime <
                    _poolInfo.depositLimiters.endTime,
                'end time should be after start time'
            );
        } else {
            _poolInfo.depositLimiters.startTime = 0;
            _poolInfo.depositLimiters.endTime = 0;
        }

        _poolInfo.funds.balance = 0;
        _poolInfo.funds.loanedBalance = 0;
        _poolInfo.uniqueUsers = 0;
        _poolInfo.interestPayoutsStarted = false;

        require(
            _poolInfo.depositLimiters.maxUtilisation <= 100,
            'Utilisation can be maximum 100%'
        );

        address _collateralToken = collateralTokenDeployer.createToken(
            address(this),
            address(_poolInfo.tokenInfo.token),
            _poolInfo.tokenInfo.token.decimals()
        );

        _poolInfo.tokenInfo.collateralToken = IBEP20(_collateralToken);

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
        _newPoolInfo.tokenInfo.collateralToken = pool.tokenInfo.collateralToken;
        _newPoolInfo.poolType = pool.poolType;

        // Check utilisation
        require(
            _newPoolInfo.depositLimiters.maxUtilisation <= 100,
            'maxUtilisation cannot exceed 100%'
        );

        (uint256 currentUtilisation, uint256 precision) = getPoolUtilisation(
            _pid
        );

        require(
            _newPoolInfo.depositLimiters.maxUtilisation.mul(precision) >=
                currentUtilisation,
            'should not set maxUtilisation less than current utilisation'
        );

        // Assign new values
        poolInfoPrivate[_pid] = _newPoolInfo;
    }

    function getPoolInfo(
        uint256 _from,
        uint256 _to
    ) external view returns (PoolInfo[] memory) {
        PoolInfo[] memory tPoolInfo = new PoolInfo[](_to - _from + 1);

        uint256 j = 0;
        for (uint256 i = _from; i <= _to; i++) {
            PoolInfo memory _poolInfoPrivate = poolInfoPrivate[i];
            _poolInfoPrivate.tokenInfo.symbol = _poolInfoPrivate
                .tokenInfo
                .token
                .symbol();
            _poolInfoPrivate.tokenInfo.decimals = _poolInfoPrivate
                .tokenInfo
                .token
                .decimals();
            tPoolInfo[j++] = _poolInfoPrivate;
        }

        return tPoolInfo;
    }

    function totalStakesOfUser(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        return userInfo[_pid][_user].length;
    }

    function getUserStakes(
        uint256 _pid,
        address _user,
        uint256 _from,
        uint256 _to
    ) external view returns (UserInfo[] memory) {
        UserInfo[] memory tUserInfo = new UserInfo[](_to - _from + 1);

        uint256 j = 0;
        for (uint256 i = _from; i <= _to; i++) {
            tUserInfo[j++] = userInfo[_pid][_user][i];
        }

        return tUserInfo;
    }

    function recoverFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
            return true;
        }

        IBEP20(_token).safeTransfer(_to, _amount);

        emit Recovered(_token, _to, _amount);

        return true;
    }

    function recoverFundsFromCollateral(
        address _collateralToken,
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_token == address(0)) {
            ICollateralToken(_collateralToken).recoverEther(_to, _amount);
            return true;
        }

        IBEP20(_token).safeTransferFrom(_collateralToken, _to, _amount);

        emit Recovered(_token, _to, _amount);

        return true;
    }

    receive() external payable {
        emit ReceivedBNB(msg.sender, msg.value);
    }

    // Events
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardHarvested(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event Whitelisted(address indexed user, uint256 indexed pid, bool status);
    event Borrowed(address indexed user, uint256 indexed pid, uint256 amount);
    event Repaid(address indexed user, uint256 indexed pid, uint256 amount);

    event Recovered(address token, address to, uint256 amount);
    event ReceivedBNB(address, uint256);
}
