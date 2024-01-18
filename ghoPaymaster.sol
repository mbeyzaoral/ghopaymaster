// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./UserOperation.sol";
import "./Interfaces/IEntryPoint.sol";
import "./baseContracts/BasePaymaster.sol";

contract GhoPaymaster is BasePaymaster {
    using UserOperationLib for UserOperation;
    using SafeERC20 for IERC20;

    // oracle instance eklenecek
    IOracle public oracle;
    IERC20 public ghoToken;

    constructor(
        address _entryPointAddress,
        address oracleAddress,
        address ghoTokenAddress
    ) BasePaymaster(IEntryPoint(_entryPointAddress)) {
        oracle = IOracle(oracleAddress);
        ghoToken = IERC20(ghoTokenAddress);
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        uint256 maxCost
    ) internal view override returns (bytes, uint256) {
        address account = userOp.getSender();
    }
}
