// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IBEP20SupplyControl is IBEP20 {
    function mintCollateralToken(address to, uint256 amount) external returns (bool);

    function burnCollateralToken(address from, uint256 amount) external returns (bool);
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

interface IReserveDeployer {
    function createReserve(
        address _stakerContract,
        address _tokenContract,
        uint8 _tokenDecimals
    ) external returns (address);
}

interface IReserve {
    function resetAllowance() external;
}

contract Staking is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    IReserveDeployer private immutable reserveDeployer;

    enum PoolType {
        Staking,
        Loan
    }

    enum TransactionType {
        Staking,
        Borrow
    }

    struct Transaction {
        TransactionType transactionType;
        uint256 amount;
        uint256 time;
        uint256 paidOut;
    }

    struct TokenInfo {
        IBEP20 token;
        IBEP20SupplyControl reserve;
        uint8 decimals;
        string name;
        string symbol;
    }

    struct DepositLimiters {
        uint256 duration; // Lockup period
        uint256 startTime; // Deposits Start Time, applicable for poolType Staking
        uint256 endTime; // Deposits End Time, applicable for poolType Staking
        uint256 limitPerUser; // Limit Per Deposit Transaction
        uint256 capacity;
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
    uint256 private oneHundred = 100;
    uint256 private percentagePrecision = 1 ether;
    uint256 private oneYear = 365 days;
    uint256 private ninetyDays = 90 days;
    uint256 private zero = 0;
    uint256 private one = 1;

    constructor(IReserveDeployer _reserveDeployer) {
        reserveDeployer = _reserveDeployer;
    }

    // Manage Pools
    function setPoolPaused(uint256 _pid, bool _flag) external onlyOwner {
        poolInfoPrivate[_pid].paused = _flag;
        emit PoolPaused(_pid, _flag);
    }

    function startInterest(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfoPrivate[_pid];

        require(pool.poolType == PoolType.Staking, 'Only applicable for pool type staking');
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

    function shouldReserveResetAllowance(
        IBEP20SupplyControl _reserve,
        IBEP20 _token,
        uint256 amount
    ) private view returns (bool) {
        return
            IBEP20(_token).allowance(address(_reserve), address(this)) < amount;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory) {
        return poolInfoPrivate[_pid];
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction[] storage transactions = user.transactions;

        require(
            user.totalAmountBorrowed == zero,
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
            pool.funds.balance.add(_amount) <= pool.depositLimiters.capacity,
            'pool capacity reached'
        );

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.reserve),
            _amount
        );

        user.totalAmountStaked = user.totalAmountStaked.add(_amount);

        pool.funds.balance = pool.funds.balance.add(_amount);

        transactions.push(
            Transaction({
                transactionType: TransactionType.Staking,
                amount: _amount,
                time: block.timestamp,
                paidOut: zero
            })
        );

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
        require(_amount <= transaction.amount, 'amount greater than available');

        if (pool.poolType == PoolType.Staking) {
            // Check if the user is withdrawing early
            require(pool.interestPayoutsStarted, INTEREST_PAYOUT_NOT_STARTED);
            require(
                block.timestamp >=
                    pool.depositLimiters.endTime.add(
                        pool.depositLimiters.duration
                    ),
                'withdrawing too early'
            );
        } else {
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
        transaction.time = block.timestamp;
        user.totalAmountStaked = user.totalAmountStaked.sub(_amount);

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
                pool.tokenInfo.reserve.totalSupply()
            );
        }

        // Update global states
        pool.funds.balance = pool.funds.balance.sub(_amount);

        deleteStakeIfEmpty(_pid, _index);

        pool.tokenInfo.reserve.burnCollateralToken(msg.sender, _originalAmount);
        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.reserve),
            msg.sender,
            _amount
        );

        emit Withdrawn(msg.sender, _pid, _amount);
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
            reward = zero;
        }

        if (reward > zero) {
            transaction.paidOut = transaction.paidOut.add(reward);
            pool.funds.balance = pool.funds.balance.sub(reward);

            if (
                shouldReserveResetAllowance(
                    pool.tokenInfo.reserve,
                    pool.tokenInfo.token,
                    _amount
                )
            ) {
                IReserve(address(pool.tokenInfo.reserve))
                    .resetAllowance();
            }

            pool.tokenInfo.token.safeTransferFrom(
                address(pool.tokenInfo.reserve),
                msg.sender,
                reward
            );

            emit RewardHarvested(msg.sender, _pid, reward);
        }

        return reward;
    }

    function borrow(uint256 _pid, uint256 _amount) public {
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.isWhitelisted, 'Only whitelisted can borrow');
        require(
            user.totalAmountStaked == zero,
            'Should withdraw all staked before borrowing'
        );

        PoolInfo storage pool = poolInfoPrivate[_pid];
        Transaction[] storage transactions = userInfo[_pid][msg.sender]
            .transactions;

        require(pool.poolType == PoolType.Loan, 'no loans from here');

        require(!pool.paused, 'Pool Paused');

        require(pool.funds.balance > zero, 'Nothing deposited');

        uint256 projectedUtilisation = calculatePercentage(
            pool.funds.loanedBalance.add(_amount),
            pool.funds.balance
        );

        require(
            projectedUtilisation <=
                pool.depositLimiters.maxUtilisation.mul(percentagePrecision),
            'utilisation maxed out'
        );

        if (
            shouldReserveResetAllowance(
                pool.tokenInfo.reserve,
                pool.tokenInfo.token,
                _amount
            )
        ) {
            IReserve(address(pool.tokenInfo.reserve))
                .resetAllowance();
        }

        pool.tokenInfo.token.safeTransferFrom(
            address(pool.tokenInfo.reserve),
            msg.sender,
            _amount
        );

        user.totalAmountBorrowed = user.totalAmountBorrowed.add(_amount);

        pool.funds.loanedBalance = pool.funds.loanedBalance.add(_amount);

        transactions.push(
            Transaction({
                transactionType: TransactionType.Borrow,
                amount: _amount,
                time: block.timestamp,
                paidOut: zero
            })
        );

        addUniqueUser(_pid);

        emit Borrowed(msg.sender, _pid, _amount);
    }

    function repay(uint256 _pid, uint256 _index, uint256 _amount) public {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Transaction storage transaction = user.transactions[_index];

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

        user.totalAmountBorrowed = user.totalAmountBorrowed.sub(_amount);

        pool.funds.loanedBalance = pool.funds.loanedBalance.sub(_amount);

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.reserve),
            _amount
        );

        pool.tokenInfo.token.safeTransferFrom(
            msg.sender,
            address(pool.tokenInfo.reserve),
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
        Transaction memory transaction = userInfo[_pid][_user].transactions[
            _index
        ];

        require(_amount <= transaction.amount, 'amount greater than available');

        if (pool.poolType == PoolType.Staking) {
            if (block.timestamp < pool.depositLimiters.endTime) {
                // No pay outs earlier than deposits end time for poolType Staking
                return zero;
            }
        }

        uint256 utilisation = getPoolUtilisation(_pid);

        if (pool.poolType == PoolType.Staking) {
            // Ignore Utilisation for PoolType Staking (use 100%)
            utilisation = oneHundred.mul(percentagePrecision);
        }

        // Context: APY is dependent on utilisation for poolType Loan. Max APY is reached on 100% utilisation
        // Max. utilisation can also limit Max. APY, if the allowed utilisation is less than 100%
        return
            (_amount.mul(pool.APY).mul(utilisation).mul(_duration)).div(
                oneHundred.mul(oneHundred).mul(oneYear).mul(percentagePrecision)
            );
    }

    function getPoolUtilisation(uint256 _pid) public view returns (uint256) {
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

    function claimQuarterlyPayout(uint256 _pid, uint256 _index) external {
        PoolInfo memory pool = poolInfoPrivate[_pid];
        Transaction memory transaction = userInfo[_pid][msg.sender]
            .transactions[_index];

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

        uint256 _duration = block.timestamp.sub(pool.depositLimiters.endTime);

        if (_duration > pool.depositLimiters.duration) {
            _duration = pool.depositLimiters.duration;
        }

        uint256 quartersPassed = (_duration).div(ninetyDays);

        require(quartersPassed > zero, 'too early');

        _duration = quartersPassed.mul(ninetyDays);

        transferRewards(_pid, _index, transaction.amount, _duration);
    }

    function whitelist(
        uint256 _pid,
        address _user,
        bool _status
    ) external onlyOwner {
        PoolInfo storage pool = poolInfoPrivate[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        require(pool.poolType == PoolType.Loan, 'no loans from here');

        user.isWhitelisted = _status;

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

        require(
            _poolInfo.depositLimiters.maxUtilisation <= 100,
            'Utilisation can be maximum 100%'
        );

        address _reserve = reserveDeployer.createReserve(
            address(this),
            address(_poolInfo.tokenInfo.token),
            _poolInfo.tokenInfo.decimals
        );

        _poolInfo.tokenInfo.reserve = IBEP20SupplyControl(_reserve);

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

        // Check utilisation
        require(
            _newPoolInfo.depositLimiters.maxUtilisation <= 100,
            'maxUtilisation cannot exceed 100%'
        );

        uint256 currentUtilisation = getPoolUtilisation(_pid);

        require(
            _newPoolInfo.depositLimiters.maxUtilisation.mul(
                percentagePrecision
            ) >= currentUtilisation,
            'should not set maxUtilisation less than current utilisation'
        );

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