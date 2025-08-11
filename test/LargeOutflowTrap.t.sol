// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LargeOutflowTrap.sol";

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    
    function setBalance(address account, uint256 amount) external {
        balanceOf[account] = amount;
    }
}

contract MockERC721 {
    mapping(address => uint256) public balanceOf;
    
    function setBalance(address owner, uint256 amount) external {
        balanceOf[owner] = amount;
    }
}

contract LargeOutflowTrapTest is Test {
    LargeOutflowTrap public trap;
    MockERC20 public mockToken1;
    MockERC20 public mockToken2;
    MockERC721 public mockNFT1;
    MockERC721 public mockNFT2;
    
    address public constant TEST_WALLET = 0x1234567890AbcdEF1234567890aBcdef12345678;
    uint256 public constant THRESHOLD = 1 ether;

    function setUp() public {
        trap = new LargeOutflowTrap();
        mockToken1 = new MockERC20();
        mockToken2 = new MockERC20();
        mockNFT1 = new MockERC721();
        mockNFT2 = new MockERC721();
        
        vm.deal(TEST_WALLET, 10 ether);
        
        mockToken1.setBalance(TEST_WALLET, 2 ether);
        mockToken2.setBalance(TEST_WALLET, 0.5 ether);
        mockNFT1.setBalance(TEST_WALLET, 3);
        mockNFT2.setBalance(TEST_WALLET, 1);
    }

    function testConstructor() public {
        assertEq(trap.myWallet(), TEST_WALLET);
        assertEq(trap.threshold(), THRESHOLD);
    }

    function testConstructorEmptyArrays() public {
        vm.expectRevert();
        trap.erc20Tokens(0);
        
        vm.expectRevert();
        trap.erc721Tokens(0);
    }

    function testCollectWithEmptyArrays() public {
        bytes memory result = trap.collect();
        
        bytes[] memory dataList = abi.decode(result, (bytes[]));
        
        assertEq(dataList.length, 1);
        
        (address wallet, address token, uint256 balance, uint8 tokenType, uint256 th) = 
            abi.decode(dataList[0], (address, address, uint256, uint8, uint256));
            
        assertEq(wallet, TEST_WALLET);
        assertEq(token, address(0));
        assertEq(balance, TEST_WALLET.balance);
        assertEq(tokenType, 0);
        assertEq(th, THRESHOLD);
    }

    function testShouldRespondWithLowAmount() public {
        bytes[] memory testData = new bytes[](1);
        testData[0] = abi.encode(TEST_WALLET, address(0), 0.5 ether, uint8(0), THRESHOLD);
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(testData);
        
        assertFalse(shouldRespond);
        assertEq(responseData, bytes(""));
    }

    function testShouldRespondWithHighAmount() public {
        bytes[] memory testData = new bytes[](1);
        testData[0] = abi.encode(TEST_WALLET, address(0), 2 ether, uint8(0), THRESHOLD);
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(testData);
        
        assertTrue(shouldRespond);
        assertEq(responseData, testData[0]);
    }

    function testShouldRespondWithMultipleData() public {
        bytes[] memory testData = new bytes[](3);
        testData[0] = abi.encode(TEST_WALLET, address(0), 0.5 ether, uint8(0), THRESHOLD);
        testData[1] = abi.encode(TEST_WALLET, address(mockToken1), 2 ether, uint8(1), THRESHOLD);
        testData[2] = abi.encode(TEST_WALLET, address(mockNFT1), 1, uint8(2), THRESHOLD);
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(testData);
        
        assertTrue(shouldRespond);
        assertEq(responseData, testData[1]);
    }

    function testShouldRespondWithEmptyData() public {
        bytes[] memory testData = new bytes[](1);
        testData[0] = bytes("");
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(testData);
        
        assertFalse(shouldRespond);
        assertEq(responseData, bytes(""));
    }

    function testShouldRespondExactThreshold() public {
        bytes[] memory testData = new bytes[](1);
        testData[0] = abi.encode(TEST_WALLET, address(0), THRESHOLD, uint8(0), THRESHOLD);
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(testData);
        
        assertFalse(shouldRespond);
        assertEq(responseData, bytes(""));
    }

    function testShouldRespondJustAboveThreshold() public {
        bytes[] memory testData = new bytes[](1);
        testData[0] = abi.encode(TEST_WALLET, address(0), THRESHOLD + 1, uint8(0), THRESHOLD);
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(testData);
        
        assertTrue(shouldRespond);
        assertEq(responseData, testData[0]);
    }

    function testCollectWithMockData() public view {
        bytes memory result = trap.collect();
        bytes[] memory dataList = abi.decode(result, (bytes[]));
        
        (address wallet, address token, uint256 balance, uint8 tokenType, uint256 th) = 
            abi.decode(dataList[0], (address, address, uint256, uint8, uint256));
            
        assertEq(wallet, TEST_WALLET);
        assertEq(token, address(0));
        assertEq(tokenType, 0);
        assertEq(th, THRESHOLD);
    }

    function testFuzzShouldRespond(uint256 amount) public {
        bytes[] memory testData = new bytes[](1);
        testData[0] = abi.encode(TEST_WALLET, address(0), amount, uint8(0), THRESHOLD);
        
        (bool shouldRespond, ) = trap.shouldRespond(testData);
        
        if (amount > THRESHOLD) {
            assertTrue(shouldRespond);
        } else {
            assertFalse(shouldRespond);
        }
    }

    function testFuzzThreshold(uint256 customThreshold, uint256 amount) public {
        vm.assume(customThreshold < type(uint256).max);
        
        bytes[] memory testData = new bytes[](1);
        testData[0] = abi.encode(TEST_WALLET, address(0), amount, uint8(0), customThreshold);
        
        (bool shouldRespond, ) = trap.shouldRespond(testData);
        
        if (amount > customThreshold) {
            assertTrue(shouldRespond);
        } else {
            assertFalse(shouldRespond);
        }
    }
}