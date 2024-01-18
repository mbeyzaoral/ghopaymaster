// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import "./UserOperation.sol";
import "./Interfaces/IEntryPoint.sol";

contract GhoPaymaster {
    struct TokenPaymasterConfig {
        /// @notice The price markup percentage applied to the token price (1e6 = 100%)
        uint256 priceMarkup;
        /// @notice Exchange tokens to native currency if the EntryPoint balance of this Paymaster falls below this value
        uint128 minEntryPointBalance;
        /// @notice Estimated gas cost for refunding tokens after the transaction is completed
        uint48 refundPostopCost;
        /// @notice Transactions are only valid as long as the cached price is not older than this value
        uint48 priceMaxAge;
    }

    constructor(
        IERC20Metadata _token,
        IEntryPoint _entryPoint,
        IERC20 _wrappedNative,
        TokenPaymasterConfig memory _tokenPaymasterConfig,
        address _owner
    ) {
        setTokenPaymasterConfig(_tokenPaymasterConfig);
        transferownership(_owner);
    }

    TokenPaymasterConfig private tokenPaymasterConfig;

    // @notice Validates a paymaster user operation and calculates the required token amount for the transaction.
    // @param userOp The user operation data.
    // @param requiredPreFund The amount of tokens required for pre-funding.
    //@return context The context containing the token amount and user sender address (if applicable).
    // @return validationResult A uint256 value indicating the result of the validation (always 0 in this implementation).
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32,
        uint256 requiredPreFund
    )
        internal
        override
        returns (bytes memory context, uint256 validationResult)
    {
        unchecked {
            uint256 priceMarkup = tokenPaymasterConfig.priceMarkup;
            /*   uint256 paymasterAndDataLength = userOp.paymasterAndData.length -
                PAYMASTER_DATA_OFFSET;
            require(
                paymasterAndDataLength == 0 || paymasterAndDataLength == 32,
                "TPM: invalid data length"
            );*/
            uint256 preChargeNative = requiredPreFund +
                (tokenPaymasterConfig.refundPostopCost * userOp.maxFeePerGas);
            // note: as price is in ether-per-token and we want more tokens increasing it means dividing it by markup
            uint256 cachedPriceWithMarkup = (cachedPrice * PRICE_DENOMINATOR) /
                priceMarkup;
            if (paymasterAndDataLength == 32) {
                uint256 clientSuppliedPrice = uint256(
                    bytes32(
                        userOp
                            .paymasterAndData[PAYMASTER_DATA_OFFSET:PAYMASTER_DATA_OFFSET +
                            32]
                    )
                );
                if (clientSuppliedPrice < cachedPriceWithMarkup) {
                    // note: smaller number means 'more ether per token'
                    cachedPriceWithMarkup = clientSuppliedPrice;
                }
            }
            uint256 tokenAmount = weiToToken(
                preChargeNative,
                cachedPriceWithMarkup
            );
            SafeERC20.safeTransferFrom(
                token,
                userOp.sender,
                address(this),
                tokenAmount
            );
            context = abi.encode(tokenAmount, userOp.sender);
            validationResult = _packValidationData(
                false,
                uint48(cachedPriceTimestamp + tokenPaymasterConfig.priceMaxAge),
                0
            );
        }
    }
}
