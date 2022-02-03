// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.7/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);

        //whom ever deployes the contrasct is the owner and msg.sender generated a address for the owner
        owner = msg.sender;
    }

    function fund() public payable {
        //50$
        uint256 minimunUsd = 1 * 10**8;
        require(
            getConversionRate(msg.value) >= minimunUsd,
            "You need to spend more ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        // what the ETH -> USD conversion rate
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // latestRoundData returns 5 elements, we need to store them or use blanks if you do not want. ()=tuple
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // cast the int256 from the interface AggregatorV3Interface to uint256
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice + ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    //modifier - restrict code/functions to be ran only by owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // this means that the validation will hapen before any code after the modifier is called
    }

    function withdraw() public payable onlyOwner {
        // only want the contract admin/owner
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
