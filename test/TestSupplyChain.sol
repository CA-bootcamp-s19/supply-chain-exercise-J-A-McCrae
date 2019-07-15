pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./SupplyChainProxy.sol";

contract TestSupplyChain {

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    enum State { ForSale, Sold, Shipped, Received } // Initialize State members
    uint public initialBalance = 1 ether; // Initialize initialBalance

    SupplyChain public contractToTest; // Declare contractToTest data type, of type SupplyChain contract
    SupplyChainProxy public proxySeller; // Declare proxySeller data type, of type SupplyChainProxy contract
    SupplyChainProxy public proxyBuyer; // Declare proxyBuyer data type, of type SupplyChainProxy contract

    string itemName = "Diamond"; // Declare itemName
    uint256 itemPrice = 100; // Declare itemPrice
    uint256 itemSku = 0; // Declare itemSku

    function() external payable {} // Allow contract to receive ether

    function beforeEach() public // Declare beforeEach function
    {
        contractToTest = new SupplyChain(); // contractToTest equals new instance of SupplyChain

        proxySeller = new SupplyChainProxy(contractToTest); // proxySeller equals new instance of SupplyChainProxy, target contractToTest
        proxyBuyer = new SupplyChainProxy(contractToTest); // proxyBuyer equals new instance of SupplyChainProxy, target contractToTest

        address(proxyBuyer).transfer(itemPrice + 1); // Give buyer enough funds to buy the item
        proxySeller.proxyAddItem(itemName, itemPrice); // Make seller put the item up for sale
    }

    function testProxyAddresses() // Test proxy contracts are configured correctly
        public
    {
        Assert.notEqual(address(proxyBuyer), address(proxySeller), "Buyer and seller addresses should be different");
        Assert.equal(address(contractToTest), address(proxySeller.getTarget()), "Target contract should be contractToTest");
        Assert.equal(address(contractToTest), address(proxyBuyer.getTarget()), "Target contract should be contractToTest");
    }

    function getItemState(uint256 _expectedSku) // Retrieve the item state
        public view
        returns (uint256)
    {
        string memory name; uint sku; uint price; uint state; address seller; address buyer;
        ( name, sku, price, state, seller, buyer) = contractToTest.fetchItem(_expectedSku);
        return state;
    }

    // buyItem

    // test for failure if user does not send enough funds
    function testForFailureIfUserDoesNotSendEnoughFunds() public {
        uint itemPayment = itemPrice - 1; // Buyer payment set to less than item price

        bool result = proxyBuyer.proxyBuyItem(itemSku, itemPayment); // Buyer tries to buy item
        Assert.isFalse(result, "Buyer bought item with insufficient funds");

        Assert.equal(getItemState(itemSku), uint256(State.ForSale), "Item should be `ForSale`"); // Verifies state
    }

    // test for purchasing an item that is not for Sale
    function testForPurchasingAnItemThatIsNotForSale() public {
        uint itemPayment = itemPrice + 1; // Buyer payment set to more than item price

        bool result = proxyBuyer.proxyBuyItem(itemSku+1, itemPayment); // Buyer tries to buy item not added
        Assert.isFalse(result, "Buyer bought item that was not for sale");

    }

    // shipItem

    // test for calls that are made by not the seller
    function testForCallsThatAreMadeByNotTheSeller() public {
        uint itemPayment = itemPrice + 1; // Buyer payment set to more than item price

        bool result = proxyBuyer.proxyBuyItem(itemSku, itemPayment); // Buyer tries to buy item
        Assert.isTrue(result, "Buyer could not buy item that was for sale");

        result = proxyBuyer.proxyShipItem(itemSku); // Buyer tries to ship item
        Assert.isFalse(result, "Buyer shipped item that was previously sold");

        Assert.equal(getItemState(itemSku), uint256(State.Sold), "Item should remain `Sold`"); // Verifies state
    }

    // test for trying to ship an item that is not marked Sold
    function testForTryingToShipAnItemThatIsNotMarkedSold() public {

        bool result = proxySeller.proxyShipItem(itemSku); // Seller tries to ship item
        Assert.isFalse(result, "Seller shipped item that was for sale");

        Assert.equal(getItemState(itemSku), uint256(State.ForSale), "Item should remain `ForSale`"); // Verifies state
    }

    // receiveItem

    // test calling the function from an address that is not the buyer
    function testCallingTheFunctionFromAnAddressThatIsNotTheBuyer() public {
        uint itemPayment = itemPrice + 1; // Buyer payment set to more than item price

        bool result = proxyBuyer.proxyBuyItem(itemSku, itemPayment); // Buyer tries to buy item
        Assert.isTrue(result, "Buyer could not buy item that was for sale");

        result = proxySeller.proxyShipItem(itemSku); // Seller tries to ship item
        Assert.isTrue(result, "Seller could not ship item that was sold");

        result = proxySeller.proxyReceiveItem(itemSku); // Seller tries to receive item
        Assert.isFalse(result, "Seller received item that was previously shipped");

        Assert.equal(getItemState(itemSku), uint256(State.Shipped), "Item should remain `Shipped`"); // Verifies state
    }

    // test calling the function on an item not marked Shipped
    function testCallingTheFunctionOnAnItemNotMarkedShipped() public {
        uint itemPayment = itemPrice + 1; // Buyer payment set to more than item price

        bool result = proxyBuyer.proxyBuyItem(itemSku, itemPayment); // Buyer tries to buy item
        Assert.isTrue(result, "Buyer could not buy item that was for sale");

        result = proxyBuyer.proxyReceiveItem(itemSku); // Buyer tries to receive item
        Assert.isFalse(result, "Buyer received item that was not shipped");

        Assert.equal(getItemState(itemSku), uint256(State.Sold), "Item should be `Sold`"); // Verifies state
    }
}
