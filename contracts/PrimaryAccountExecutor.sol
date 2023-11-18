// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IStargateReceiver} from "./IStargateReceiver.sol";
import {IUniswapV3PoolActions} from "./IUniswapV3PoolActions.sol";

contract PrimaryAccountExecutor is IStargateReceiver {
  contract TokenInfo {
    address uniswapPool;
    bool uniswapZeroForOne;
  }

  address stargateRouter;
  address sponsor;
  address primaryToken;
  mapping (address => TokenInfo) supportedTokens;


  function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256,                  
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens  
        bytes memory payload
    ) external {
      require(msg.sender == stargateRouter, "DL: only stargate router can call");
      require(abi.encodePacked(address(this)) == _srcAddress, "DL: bad source address");

      TokenInfo tokenInfo = supportedTokens[_token];
      require(tokenInfo.uniswapPool != address(0), "DL: unsupported token");

      uint256 (initialAmountNormalized) = abi.decode(payload, (uint256));

      // probably should approve to tokenInfo.uniswapPool?

      // Swap the received token to primary token
      if (_token != primaryToken) {
        IUniswapV3PoolActions(tokenInfo.uniswapPool).swap(
          address(this),  // recepient
          tokenInfo.uniswapZeroForOne,
          amountLD,  // positive = exact amount in
          ?????????,
          bytes("")
        );
      }

    }
}