pragma solidity 0.5.16;

import "./provableAPI.sol";

contract CoinFlip is usingProvable{

    //VARIABLES & Structs
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1; //1 Byte gives 256 possible combinations! 1 Byte = 8 bits!


    struct Bet{
      address payable player;
      uint betValue;
      bool result;
    }


    //EVENTS
    event betTaken(address indexed player, bytes32 Id, uint betValue, bool result);
    event betPlaced(address indexed player, bytes32 queryID, uint value);
    event contractFunded(address owner, uint funds);
    event LogNewProvableQuery(string description);
    event generatedRandomNumber(uint256 randomNumber);
    event CoinFlipped(string result);

    //Mappings
    mapping (bytes32 => Bet) public bets; //Connects queryID to respective bet
    mapping(address => bool) public waiting; //connects player to result, this is the waiting system



    address owner;
    uint contractBalance = 0;
    string result;

    constructor() public payable{
        owner = msg.sender;
    }



    function placeBet(bool _bet) public payable returns(string memory){
      require(msg.value <= contractBalance/2, "Insufficient contract Balance to pay potential wins! Bet Lower!");
      require(contractBalance >= msg.value*2, "Insufficient funds in contract to pay out possible win. Please bet lower!");
      waiting[msg.sender] = true;

      uint256 QUERY_EXECUTION_DELAY = 0;
      uint256 GAS_FOR_CALLBACK = 200000;
      bytes32 queryID = provable_newRandomDSQuery(
          QUERY_EXECUTION_DELAY,
          NUM_RANDOM_BYTES_REQUESTED,
          GAS_FOR_CALLBACK
        );

        bets[queryID] = Bet({player: msg.sender, betValue: msg.value, result: false});

          emit betPlaced(msg.sender, queryID, msg.value);
          emit LogNewProvableQuery("Provable query was sent, standing for the answer.");


      if (_bet == true && bets[queryID].result == true){
        contractBalance -= msg.value * 2;
        msg.sender.transfer(msg.value * 2);
        result = "You WIN!";
        emit CoinFlipped(result);
      }
      else if(_bet == false && bets[queryID].result == false){
        contractBalance -= msg.value * 2;
        msg.sender.transfer(msg.value * 2);
        result = "You WIN!";
        emit CoinFlipped(result);
      }
      else{
        contractBalance += msg.value;
        result = "You LOOSE! Try Again!";
        emit CoinFlipped(result);
      }

        return result;
    }

    function __callback(bytes32 _queryID, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress());

        if (provable_randomDS_proofVerify__returnCode(_queryID, _result, _proof) != 0) {
                  /*
                   * @notice  The proof verification has failed! Handle this case
                   *          however you see fit. --> Not sure what to do here.
                  */
              }
              else {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2; //Generating random Number between 0 and 1
        if(randomNumber == 1){
          bets[_queryID].result = true;
        }
        else if (randomNumber == 0)
        {
          bets[_queryID].result = false;
        }
        emit generatedRandomNumber(randomNumber);
    }
        waiting[msg.sender] = false;

        emit betTaken(bets[_queryID].player, _queryID, bets[_queryID].betValue, bets[_queryID].result);
    }




        function deposit() public payable{
            require(msg.sender == owner, "Only owner can send money to contract!");
            contractBalance += msg.value;
            emit contractFunded(owner, msg.value);
        }

        function getContractBalance() public view returns(uint){
          return contractBalance;
        }

        function withdraw() public payable returns(uint){
          require(msg.sender == owner, "Only owner can withdraw!");
          msg.sender.transfer(contractBalance);
          contractBalance = 0;
          return contractBalance;
        }



}
