//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract scratchOff {

    uint public lotteryFunds;
    uint public playerFunds;
    address payable owner;
    //uint public tickets;
    address[] public playerAddresses;
    mapping(address => Player) public players;
    //address[] public players;

    struct Player {
        uint funds;
        uint tickets;
    }
 

    constructor(){
        lotteryFunds = address(this).balance;
        owner = payable(msg.sender);
        playerFunds = 0;
        //tickets = 0;
    }

    receive() external payable{}

    function openAccount() public payable {
        require(msg.value >= .0005 ether, ".0005 ether required to open account");
        Player memory _player = Player(msg.value - .0005 ether,0);
        players[msg.sender] = _player;
        playerAddresses.push(msg.sender);
        playerFunds += players[msg.sender].funds;
    }

    function fundAccount() public payable {
        players[msg.sender].funds += msg.value;
        playerFunds += msg.value;
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
            playerFunds += 1 ether;
        } else{
            players[msg.sender].tickets--;
            playerFunds -= 2 ether;
        }
    }

    function takePayout() public {
        if(players[msg.sender].funds > address(this).balance){
            (bool success,) = msg.sender.call{value: address(this).balance}("");
            require(success, "Not paid");
            playerFunds -= address(this).balance;
            players[msg.sender].funds -= address(this).balance;
        
        } else {
            (bool success,) = msg.sender.call{value: players[msg.sender].funds}("");
            require(success, "Not paid");
            playerFunds -= players[msg.sender].funds;
            players[msg.sender].funds = 0;
        }
    }

    function fundCasino() public payable{
        require(msg.sender == owner, "not owner");
        lotteryFunds += msg.value;
    }

    function takeProfits(uint amount) public {
        require(msg.sender == owner, "not the owner, buster");
        if(amount >= address(this).balance){
            (bool success,) = owner.call{value: address(this).balance}("");
            require(success, "Not paid");
            lotteryFunds = 0;
        } else{
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Not paid");
            lotteryFunds -= amount;
        }
    }

    function closeCasino() public {
        require(msg.sender == owner, "not the owner, buster");
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Not paid");
    }

}
