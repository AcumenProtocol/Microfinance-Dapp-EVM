// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IStaking {
    function handleCollateralTokenTransfer(
        uint256 _pid,
        address from,
        address to,
        uint256 amount
    ) external;
}

contract Reserve is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    address private immutable _tokenContract;
    address private immutable _stakerContract;
    uint8 private immutable _decimals;
    uint256 private immutable _pid;

    constructor(
        address stakerContract,
        address tokenContract,
        uint8 _tokenDecimals,
        uint256 pid
    ) ERC20('Staking Collateral Token', 'SCT') {
        _decimals = _tokenDecimals;

        _transferOwnership(stakerContract);

        _tokenContract = tokenContract;
        _stakerContract = stakerContract;

        _pid = pid;
    }

    function resetAllowance() external onlyOwner {
        IERC20(_tokenContract).approve(_stakerContract, type(uint256).max);
    }

    function mintCollateralToken(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        _mint(_to, _amount);

        return true;
    }

    function burnCollateralToken(
        address _from,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        burnFrom(_from, _amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (msg.sender != _stakerContract) {
            require(to != address(this), 'Should not transfer to reserve!');
        }

        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        _transfer(from, to, amount);

        if (
            from != address(this) &&
            from != _stakerContract &&
            to != _stakerContract
        ) {
            IStaking(_stakerContract).handleCollateralTokenTransfer(
                _pid,
                from,
                to,
                amount
            );
        }

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (msg.sender != _stakerContract) {
            require(to != address(this), 'Should not transfer to reserve!');
        }

        address owner = _msgSender();

        _transfer(owner, to, amount);

        if (
            owner != address(this) &&
            owner != _stakerContract &&
            to != _stakerContract
        ) {
            IStaking(_stakerContract).handleCollateralTokenTransfer(
                _pid,
                owner,
                to,
                amount
            );
        }

        return true;
    }

    /**
     * @dev Override reason for burn functions: 
     * Only the staker contract should have the authority to burn
     */
    function burn(uint256 amount) public virtual override onlyOwner {
        _burn(_msgSender(), amount);
    }
    
    function burnFrom(
        address account,
        uint256 amount
    ) public virtual override onlyOwner {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

contract ReserveDeployer {
    function createReserve(
        address _stakerContract,
        address _tokenContract,
        uint8 _tokenDecimals,
        uint256 _pid
    ) external returns (address) {
        Reserve _deployed = new Reserve(
            _stakerContract,
            _tokenContract,
            _tokenDecimals,
            _pid
        );

        return address(_deployed);
    }
}
