pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

// @title Proxy test contract based on https://www.trufflesuite.com/tutorials/testing-for-throws-in-solidity-tests

contract SupplyChainProxy {

    SupplyChain public supplyChain; // Declare supplyChain data type, of type SupplyChain contract

    constructor(SupplyChain _contractToTest) public { // Accept parameter _contractToTest, of type SupplyChain contract
         supplyChain = _contractToTest; // supplyChain equals new instance of _contractToTest
    }

    function() external payable {} // Allow contract to receive ether

    function getTarget()
        public view
        returns (SupplyChain) // Return data, of type SupplyChain contract
    {
        return supplyChain; // Return supplyChain
    }

    // Add item
    function proxyAddItem(string memory itemName, uint256 itemPrice)
        public
    {
        // Call contract supplyChain, function addItem
        supplyChain.addItem(itemName, itemPrice);
    }

    // Buy item
    function proxyBuyItem(uint256 sku, uint256 itemPayment)
        public
        returns (bool)
    {
        // Call contract supplyChain, function buyItem, sending itemPayment. Return true/false if call succeeded.
        (bool noErrors, ) = address(supplyChain).call.value(itemPayment)(abi.encodeWithSignature("buyItem(uint256)", sku));
        return noErrors;
    }

    // Ship item
    function proxyShipItem(uint256 sku)
        public
        returns (bool)
    {
        // Call contract supplyChain, function shipItem. Return true/false if call succeeded.
        (bool noErrors, ) = address(supplyChain).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        return noErrors;
    }

    // Receive item
    function proxyReceiveItem(uint256 sku)
        public
        returns (bool)
    {
        // Call contract supplyChain, function ReceiveItem. Return true/false if call succeeded.
        (bool noErrors, ) = address(supplyChain).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
        return noErrors;
    }
}





