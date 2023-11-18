// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IStargateRouter} from "./IStargateRouter.sol";

contract MinorAccountExecutor {
    struct TokenInfo {
        uint256 localStargatePool;
        uint256 primaryChainStargatePool;
    }

    mapping (address => TokenInfo) public supportedTokens;
    address stargateRouter;
    uint256 primaryLZChainId;
    address sponsor;

    constructor(
        address[] _tokenAddresses,
        TokenInfo[] tokenInfos,
        address _stargateRouter,
        uint256 _primaryLZChainId
        address _sponsor
    ) {
        uint256 length = tokenNames.length;
        require(length == tokenAddresses.length);

        for (uint256 i = 0; i < length; i++) supportedTokens[_tokenAddresses[i]] = tokenInfos[i];

        stargateRouter = _stargateRouter;
        primaryLZChainId = _primaryLZChainId;
        sponsor = _sponsor;
    }

    // Bridges to the primary account on Polygon.
    // Works only with supported ERC20 stablecoins.
    // When bridged, specifies the source amount of tokens, so that
    // the user can be reimbursed on the destination chain and get the exact amount
    // as they had on the source chain.
    function bridgeToPrimaryAccount(address token) public {
        TokenInfo tokenInfo = supportedTokens[token];
        require(tokenInfo.localStargatePool != address(0), "DL: unsupported token"); 
        
        uint256 ownedAmount IERC20(token).balanceOf(address(this));
        require(ownedAmount > 0, "DL: you dont own this token")
        
        // ownedAmount with 18 decomals
        uint256 ownedAmountNormalized = ownedAmount * 10 ** (18 - IERC20(token).decimals());

        uint256 minReceived = ownedAmount * 199 / 200;  // 0.5% slippage allowed

        IStargateRouter(stargateRouter).quoteLayerZeroFee(
            tokenInfo.primaryLZChainId,
            uint8(1),  // functionType. Always 1 for swap().
            abi.encodePacked(address(this)),  // destination address
            abi.encode(ownedAmount), // additional payload
            ({
                dstGasForCall: 0,       // extra gas, if calling smart contract,
                dstNativeAmount: 0,     // amount of dust dropped in destination wallet 
                dstNativeAddr: taskArgs.dstNativeAddr // destination wallet for dust
            }),
        );
        
        IStargateRouter(stargateRouter).swap{value: msg.value}(
            primaryLZChainId, // chain to transfer to
            tokenInfo.localStargatePool, // source pool id
            tokenInfo.primaryChainStargatePool, // destination pool id
            msg.sender, // refund adddress. extra gas (if any) is returned to this address
            ownedAmount, // quantity to swap in LD, (local decimals)
            minReceived, // the min qty you would accept in LD (local decimals)
            IStargateRouter.lzTxObj(0, 0, "0x"), // 0 additional gasLimit increase, 0 airdrop, at 0x address
            abi.encodePacked(address(this)), // the address to send the tokens to on the destination
            abi.encode(ownedAmountNormalized) // additional payload
        );
    }
}
