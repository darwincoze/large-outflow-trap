// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

contract LargeOutflowTrap is ITrap {
    address public immutable myWallet;
    uint256 public immutable threshold;
    address[] public erc20Tokens;
    address[] public erc721Tokens;

    constructor() {
        myWallet = 0x1234567890AbcdEF1234567890aBcdef12345678; // change to your wallet address
        threshold = 1 ether; // example: default threshold 1 ETH
        erc20Tokens = new address[](0); // example: empty/default array, replace with the address according to your wishes
        erc721Tokens = new address[](0); // example: empty/default array, replace with the address according to your wishes
    }

    function collect() external view override returns (bytes memory) {
        uint256 ethBalance = myWallet.balance;
        uint256 totalAssets = 1 + erc20Tokens.length + erc721Tokens.length;
        bytes[] memory dataList = new bytes[](totalAssets);

        dataList[0] = abi.encode(myWallet, address(0), ethBalance, uint8(0), threshold);

        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            uint256 bal = IERC20(erc20Tokens[i]).balanceOf(myWallet);
            dataList[1 + i] = abi.encode(myWallet, erc20Tokens[i], bal, uint8(1), threshold);
        }

        for (uint256 i = 0; i < erc721Tokens.length; i++) {
            uint256 bal = IERC721(erc721Tokens[i]).balanceOf(myWallet);
            dataList[1 + erc20Tokens.length + i] = abi.encode(myWallet, erc721Tokens[i], bal, uint8(2), threshold);
        }

        return abi.encode(dataList);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].length < 1) continue;

            (, , uint256 amount, , uint256 th) = abi.decode(data[i], (address, address, uint256, uint8, uint256));

            if (amount > th) {
                return (true, data[i]);
            }
        }

        return (false, bytes(""));
    }
}
