//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';


contract scratchOff is VRFConsumerBaseV2{
    uint private lotteryFunds;
    uint private playerFunds;
    uint private playerTickets;
    uint public oracleValue;
    bool public randNumFulfilled;
    address payable private owner;
    address[] private playerAddresses;
    mapping(address => Player) private players;
    bool fulfilled;
    uint[] randomNumber;
    uint requestStatusId;


    struct Player {
        uint funds;
        uint tickets;
    }
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    /**
     * HARDCODED FOR GOERLI
     * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
     */

    function requestRandomWords() private returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
    }

    function getRequestStatus(uint256 _requestId) private view returns (bool done, uint256[] memory randWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
        constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = subscriptionId;
        lotteryFunds = address(this).balance;
        owner = payable(msg.sender);
        playerFunds = 0;
        playerTickets = 0;
        oracleValue = 0;
        lotteryFunds = 0;
        randNumFulfilled = true;
    }

    receive() external payable{}

    function fundAccount() public payable {
        //check if player has an account
        if(contains(msg.sender)) {
            //allow players to fund their accounts
            players[msg.sender].funds += msg.value;
            playerFunds += msg.value;
        } else { //create a new account
            require(msg.value >= 5 wei, "5 wei required to open account");
            //charge .0005 eth to open an account
            Player memory _player = Player(msg.value - 5 wei,0);
            lotteryFunds += 5 wei;
            players[msg.sender] = _player;
            //add player's address to list of addresses to keep account
            playerAddresses.push(msg.sender);
            //add any funds over .0005 eth to total player funds
            playerFunds += players[msg.sender].funds;
        }
    }

    function buyTicket() public {
        //remove 2 eth from address account and add a ticket
        require(players[msg.sender].funds >= 2 wei, "add wei to your account");
        //don't allow a player to buy a ticket if the casino can't afford a payout
        require(lotteryFunds >= 1 wei + playerTickets * 1 wei, "casino closed for lack of funding");
        players[msg.sender].funds -= 2 wei;
        players[msg.sender].tickets++;
        playerTickets++;
    }

    function play() public {
        require(players[msg.sender].tickets > 0, "No tickets!");  //check if player has a ticket
        require(randNumFulfilled == true, "please call pushRandomNum()");
        if(oracleValue < 10) {
            randNumFulfilled = false;
            getRandNum();
        } else{
            lotteryFunds += 2 wei;
            playerFunds -= 2 wei;
            playerTickets--;
            players[msg.sender].tickets--;
            if(oracleValue % 2 == 0) {
                players[msg.sender].funds += 3 wei;
                playerFunds += 3 wei;
                lotteryFunds -= 3 wei;
            }
            oracleValue = oracleValue/10;
        }
        
    }

    function takePayout() public {
        //check if player is owed more money than exists in the casino (shouldn't ever get executed)
        if(players[msg.sender].funds > address(this).balance){
            (bool success,) = msg.sender.call{value: address(this).balance}("");
            require(success, "Not paid");
            playerFunds -= address(this).balance;
            players[msg.sender].funds -= address(this).balance;
        //pay the player their balance
        } else {
            (bool success,) = msg.sender.call{value: players[msg.sender].funds}("");
            require(success, "Not paid");
            playerFunds -= players[msg.sender].funds;
            players[msg.sender].funds = 0;
        }
    }

    function fundCasino() public payable {
        //allow casino owner to fund the casino
        require(msg.sender == owner, "not owner");
        lotteryFunds += msg.value;
    }

    function takeProfits(uint amount) public {
        //allow casino owner to take money from the casino
        require(msg.sender == owner, "not the owner, buster");
        if(amount >= address(this).balance - playerFunds) { //Don't allow owner to take funds in player accounts
            (bool success,) = owner.call{value: address(this).balance - playerFunds}("");
            require(success, "Not paid");
            lotteryFunds = 0;
        } else {
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Not paid");
            lotteryFunds -= amount;
        }
    }

    function closeCasino() public {
        //give owner all casino profits
        require(msg.sender == owner, "not the owner, buster");
        (bool success,) = owner.call{value: address(this).balance - playerFunds}("");
        require(success, "Not paid");
        lotteryFunds = 0;
        //return funds to all players and reimburse players for tickets already purchased
        for (uint i = 0; i < playerAddresses.length; i++) {
            (bool _success,) = playerAddresses[i].call{value: players[playerAddresses[i]].funds + players[playerAddresses[i]].tickets * 2 wei}("");
             require(_success, "Not paid");
             playerFunds -= players[playerAddresses[i]].funds;
             players[playerAddresses[i]].funds = 0;
        }
    }
    //check if player already has an account
    function contains(address _address) private view returns(bool){
        for(uint i = 0; i < playerAddresses.length; i++){
            if(playerAddresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getFunds() public view returns(uint) {
        return players[msg.sender].funds;
    }

    function getTickets() public view returns(uint){
        return players[msg.sender].tickets;
    }

    function getPlayers(address _address) public view returns(Player memory){
        require(msg.sender == owner, "only the owner can view players");
        return players[_address];
    }

    function getPlayerAddresses() public view returns(address[] memory){
        require(msg.sender == owner, "only the owner can view player addresses");
        return playerAddresses;
    }

    function getLotteryFunds() public view returns(uint){
        require(msg.sender == owner, "only owner can view that");
        return lotteryFunds;
    }

    function getPlayerfunds() public view returns(uint){
        require(msg.sender == owner, "only owner can view that");
        return playerFunds;
    }


    function randNumGetter() public view returns(uint) {
        require(msg.sender == owner);
        return oracleValue;
    }


    function getRandNum() private {
        requestStatusId = requestRandomWords();
        uint num = lastRequestId;
        require(requestStatusId == num, "id does not match last request");
        (fulfilled, randomNumber) = getRequestStatus(requestStatusId);
    }

    function pushRandomNum() public returns(bool) {
        (fulfilled, randomNumber) = getRequestStatus(requestStatusId);
        if(fulfilled == true){
            oracleValue = randomNumber[0];
            randNumFulfilled = true;
            return true;
        }
        return false;
        
    }
}
