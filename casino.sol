//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract scratchOff {

    uint lotteryFunds;
    uint public playerbalance;
    address payable player;
    address payable owner;
    uint public tickets;

    constructor(){
        lotteryFunds = address(this).balance;
        player = payable(msg.sender);
        owner = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        tickets = 0;
    }
    receive() external payable{}
    
    function buyTicket() public payable {
        require(msg.value == 2 ether, "not enough ether");
        require(lotteryFunds >= 2 ether, "casino closed for lack of funding");
        tickets++;
    }

    function play(uint num) public {
        require(tickets > 0, "No tickets!");
        if(num % 2 == 0){
            playerbalance = (playerbalance + 3 ether);
        }
            tickets--;
    }

    function takePayout() public {
        (bool success,) = msg.sender.call{value: playerbalance}("");
        require(success, "Not paid");
        playerbalance = 0;
        
    }

    function fundLottery() public payable{
        require(msg.sender == owner, "not owner");
        lotteryFunds = address(this).balance - playerbalance;
    }

    function takeProfits(uint amount) public {
        if(amount >= address(this).balance){
            (bool success,) = owner.call{value: address(this).balance}("");
            require(success, "Not paid");
        } else{
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Not paid");
        }
  }

    function thisContract() public view returns(address){
        return(address(this));
    }

}
