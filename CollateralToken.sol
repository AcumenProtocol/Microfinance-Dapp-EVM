// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Reserve is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    address private immutable tokenContract;
    address private immutable stakerContract;
    uint8 private immutable _decimals;

    constructor(
        address _stakerContract,
        address _tokenContract,
        uint8 _tokenDecimals
    ) ERC20('Staking Collateral Token', 'SCT') {
        _decimals = _tokenDecimals;

        _transferOwnership(_stakerContract);

        tokenContract = _tokenContract;
        stakerContract = _stakerContract;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

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

    function resetAllowance() external onlyOwner {
        IERC20(tokenContract).approve(stakerContract, type(uint256).max);
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
}

contract ReserveDeployer {
    function createReserve(
        address _stakerContract,
        address _tokenContract,
        uint8 _tokenDecimals
    ) external returns (address) {
        Reserve _deployed = new Reserve(
            _stakerContract,
            _tokenContract,
            _tokenDecimals
        );

        return address(_deployed);
    }
}
