// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TokenX is ERC20{


    constructor()ERC20("TokenX", "TKX"){
        _mint(msg.sender, 1000000e18);
    }

}