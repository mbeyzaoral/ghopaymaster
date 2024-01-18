// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./UserOperation.sol";
import "./Interfaces/IEntryPoint.sol";
import "./baseContracts/BasePaymaster.sol";
import "./helpers/OracleConverter.sol";

contract GhoPaymaster is BasePaymaster {
    using UserOperationLib for UserOperation;
    using SafeERC20 for IERC20;

    // oracle instance eklenecek
    Oracle public oracle;
    IERC20 public ghoToken;
    uint256 public immutable ghoPrice = 1;

    constructor(
        address _entryPointAddress,
        address oracleAddress,
        address ghoTokenAddress
    ) BasePaymaster(IEntryPoint(_entryPointAddress)) {
        oracle = Oracle(oracleAddress);
        ghoToken = IERC20(ghoTokenAddress);
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        uint256 maxCost
    ) internal view override returns (bytes, uint256) {
        address account = userOp.getSender();
        uint256 gasPriceUserOp = userOp.gasPrice();
        uint256 maxTokenCost = getTokenValueOfEth(maxCost);

        SafeERC20.safeTransferFrom(
            token,
            userOp.sender,
            address(this),
            tokenAmount
        );

        bytes context = abi.encode(
            account,
            gasPriceUserOp,
            maxTokenCost,
            maxCost
        );
        uint256 validationData = 0;
        return (context, validationData);
    }

    function getTokenValue(uint amount) public view returns (uint256) {
        uint256 ethPrice = oracle.getPrice();
        return (ethPrice * ethAmount) / 1000000000000000000;
    }

    receive() external payable {}
}
