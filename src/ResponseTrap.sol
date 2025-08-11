// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IResponse {
    function executeResponse(bytes calldata _txData) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract ResponseTrap is IResponse {
    address public immutable safeWallet;

    event ResponseExecuted(address indexed from, address indexed to, uint256 amount, uint8 assetType);

    constructor(address _safeWallet) {
        require(_safeWallet != address(0), "Invalid safe wallet");
        safeWallet = _safeWallet;
    }

    function executeResponse(bytes calldata _txData) external override {
        (address from, address tokenAddr, uint256 amount, uint8 assetType, ) =
            abi.decode(_txData, (address, address, uint256, uint8, uint256));

        if (assetType == 0) {
            payable(safeWallet).transfer(amount);
        } else if (assetType == 1) {
            IERC20(tokenAddr).transfer(safeWallet, amount);
        } else if (assetType == 2) {
            uint256 balance = IERC721(tokenAddr).balanceOf(from);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = IERC721(tokenAddr).tokenOfOwnerByIndex(from, 0);
                IERC721(tokenAddr).safeTransferFrom(from, safeWallet, tokenId);
            }
        }

        emit ResponseExecuted(from, safeWallet, amount, assetType);
    }

    receive() external payable {}
}
