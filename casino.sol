//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract scratchOff {

    uint lotteryFunds;
    uint public playerbalance;
    address payable player;
    address payable owner;
    //uint public tickets;
    address[] public playerAddresses;
    mapping(address => Player) players;
    //address[] public players;

    struct Player {
        uint funds;
        uint tickets;
    }
 

    constructor(){
        lotteryFunds = address(this).balance;
        player = payable(msg.sender);
        owner = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        //tickets = 0;
    }

    receive() external payable{}


    function openAccount() public payable {
        require(msg.value == .0005 ether, ".0005 ether required to open account");
        Player memory _player = Player(0,0);
        players[msg.sender] = _player;
        playerAddresses.push(msg.sender);
    }

    function fundAccount() public payable {
        players[msg.sender].funds += msg.value;
    }

    function buyTicket() public {
        require(players[msg.sender].funds >= 2 ether, "add ether to your account");
        require(lotteryFunds >= 2 ether, "casino closed for lack of funding");
        players[msg.sender].funds -= 2 ether;
        players[msg.sender].tickets++;
    }

    function play(uint num) public {
        require(players[msg.sender].tickets > 0, "No tickets!");
        if(num % 2 == 0){
            players[msg.sender].funds += 3 ether;
        }
            players[msg.sender].tickets--;
    }

    function takePayout() public {
        (bool success,) = msg.sender.call{value: players[msg.sender].funds}("");
        require(success, "Not paid");
        players[msg.sender].funds = 0;
        
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

}
