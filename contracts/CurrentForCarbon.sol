// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;
import "./C2COwnable.sol";
import "./DateLib.sol";

/// @title CurrentForCarbon
/// @author Dave Hardin
/// notice 
contract CurrentForCarbon is C2COwnable {
    using DateLib for DateLib.DateTime;

    struct GamePlayer {
        string gamePlayerID;
        bytes32 gamePlayerSignature; // sha256 of dataConnectionString, gamePlayerAddress, gamePlayerID
        string dataConnectionString;
        address gamePlayerAddress;  
        bool signatureMatches;
        string status;
    }

    struct GameEvent {
        string gameEventID;    
        bytes32 gameEventSignature;
        string gameEventName;    
        string gameEventType;  
        string gameEventStartTime;     
        string gameEventEndTime;       
        string gameEventDuration;
        string dollarPerPoint;
        string pointsPerWatt;
        string pointsPerPercent;
     }

    struct GameResult {
        bytes32 gameResultSignature;  //sha256 of playerid + eventID
        string gamePlayerID;   
        string gameEventID;    
        address gamePlayerAddress;   
        bytes32 gamePlayerSignature;
        string averagePowerInWatts;
        string baselineAveragePowerInWatts;
        string deltaAveragePowerInWatts;
        string percentPoints;
        string wattPoints;
        string totalPointsAwarded;
        string awardValue;
        string status;
    }
   
   struct GameResultLocals {
        bytes32 eventHash;
        bytes32 resultHash;    
        uint eventIndex;
        uint resultIndex;
        bytes32 gamePlayerIDIdx;
        GameResult gameResult;       
     }
   // EVENTS
   
   event GamePlayerEvent(
        uint indexed slice,
        string gamePlayerID,
        string dataConnectionString,
        address gamePlayerAddress,
        string status
   );

    event GameEventEvent(
        uint indexed slice,
        string gameEventID,
        string gameEventName,
        string gameEventType,  
        string gameEventStartTime,
        string gameEventEndTime,     
        string gameEventDuration,
        string dollarPerPoint,
        string pointsPerWatt,
        string pointsPerPercent
    );

    event GameResultEvent(
        uint indexed slice,
        bytes32 indexed gamePlayerIDIdx,
        string gameEventStartTime,
        string gamePlayerID,
        string gameEventID,
        string averagePowerInWatts,
        string baselineAveragePowerInWatts,
        string deltaAveragePowerInWatts,
        string percentPoints,
        string wattPoints,
        string totalPointsAwarded,
        string awardValue
    );
  
  event GameCombinedEventResultEvent(
            uint indexed slice,
            bytes32 indexed gamePlayerIDIdx,
            string gamePlayerID,
            string gameEventID,
            string gameEventStartTime,
            string gameEventDuration,
            string pointsPerWatt,
            string averagePowerInWatts,
            string baselineAveragePowerInWatts,
            string deltaAveragePowerInWatts,
            string wattPoints,
            string awardValue
        );


    struct PlayerState {
        uint slice;
        uint count;
    }

    struct EventState {
        uint slice;
        uint count;
    }

    struct ResultState {
        uint slice;
        uint count;
    }


    GamePlayer[] _gamePlayers;
    mapping(bytes32 => uint) _gamePlayerIDHashToIndex;
    GameEvent[] _gameEvents;
    mapping(bytes32 => uint) _gameEventIDHashToIndex;
    GameResult[] _gameResults;
    mapping(bytes32 => uint) _gameResultIDHashToIndex;

    PlayerState _playerState;
    EventState _eventState;
    ResultState _resultState;

    uint _sliceSize = 9999;
 
    /// External State Variables

    string public _contractName;
    
    bool public HasResultReadyFlag = false;

    uint public PlayerCount = 0;
    uint public EventCount = 0;
    uint public ResultCount = 0;

 
    /// construction of contract
    constructor ()  {
        _contractName = "Upperbay Systems CurrentForCarbon V1";

        _playerState.slice = 0;
        _playerState.count = 0;

        _eventState.slice = 0;
        _eventState.count = 0;

        _resultState.slice = 0;
        _resultState.count = 0;

    }
  
    // function _getDataItemIndex(bytes32 _dataItemId) private view returns (uint) {
    //     return dataItemIdToIndex[_dataItemId]-1;
    // }
      
    function GamePlayerExists(bytes32 _gamePlayerIDHash) public view returns (bool) {
        if (_gamePlayers.length == 0)
            return false;
        uint index = _gamePlayerIDHashToIndex[_gamePlayerIDHash];
        return (index > 0);
    }

    function GameEventExists(bytes32 _gameEventIDHash) public view returns (bool) {
        if (_gameEvents.length == 0)
            return false;
        uint index = _gameEventIDHashToIndex[_gameEventIDHash];
        return (index > 0);
    }

    function GameResultExists(bytes32 _gameResultIDHash) public view returns (bool) {
        if (_gameResults.length == 0)
            return false;
        uint index = _gameResultIDHashToIndex[_gameResultIDHash];
        return (index > 0);
    }

    

    function  AddGamePlayer (
        string memory gamePlayerID,
        address playerAddress,
        string memory dataConnectionString
       
        )  public { //onlyOwner

        //hash the crucial info to get a unique id
        //bytes32 id = keccak256(abi.encodePacked(_name, _description, _accessPath, _creationTime));
        bytes32 gamePlayerSignature = sha256 (abi.encodePacked(dataConnectionString, playerAddress,gamePlayerID));
        bytes32 gamePlayerIDHash = sha256 (abi.encodePacked(gamePlayerID));
        //require that the match be unique (not already added)
        require(!GamePlayerExists(gamePlayerIDHash));

        GamePlayer memory gamePlayer;
        gamePlayer.gamePlayerID = gamePlayerID; 
        gamePlayer.dataConnectionString = dataConnectionString;   
        gamePlayer.gamePlayerAddress = playerAddress;
        gamePlayer.gamePlayerSignature = gamePlayerSignature;
        gamePlayer.status = "active";
           
        _gamePlayers.push(gamePlayer);
        uint newIndex = _gamePlayers.length - 1;
        _gamePlayerIDHashToIndex[gamePlayerIDHash] = newIndex;

        _playerState.count++;
        _playerState.slice = _playerState.count/_sliceSize;
        PlayerCount = _playerState.count;

        emit GamePlayerEvent(
                             _playerState.slice,
                            gamePlayer.gamePlayerID,
                            gamePlayer.dataConnectionString,
                            gamePlayer.gamePlayerAddress,
                            gamePlayer.status
                            );
    }

    function AddGameEvent (
        string memory gameEventID,
        string memory gameEventName,
        string memory gameEventType,
        string memory gameEventStartTime,
        string memory gameEventEndTime,     
        string memory gameEventDuration,
        string memory dollarPerPoint,
        string memory pointsPerWatt,
        string memory pointsPerPercent
        )  public 
    { //onlyOwner

        //hash the crucial info to get a unique id
        //bytes32 id = keccak256(abi.encodePacked(_name, _description, _accessPath, _creationTime));
        bytes32 gameEventIDHash = sha256 (abi.encodePacked(gameEventID));
        
        //require that the match be unique (not already added)
        require(!GamePlayerExists(gameEventIDHash));
        
        GameEvent memory gameEvent;
        gameEvent.gameEventSignature = gameEventIDHash;
        gameEvent.gameEventID = gameEventID;
        gameEvent.gameEventName = gameEventName;
        gameEvent.gameEventType = gameEventType;
        gameEvent.gameEventStartTime = gameEventStartTime;
        gameEvent.gameEventEndTime = gameEventEndTime;
        gameEvent.gameEventDuration = gameEventDuration;
        gameEvent.dollarPerPoint = dollarPerPoint;
        gameEvent.pointsPerWatt = pointsPerWatt;
        gameEvent.pointsPerPercent = pointsPerPercent;

        _gameEvents.push(gameEvent);
        uint newIndex = _gameEvents.length - 1;
        _gameEventIDHashToIndex[gameEventIDHash] = newIndex;


        _eventState.count++;
        _eventState.slice = _eventState.count/_sliceSize;
        EventCount = _eventState.count;


        emit GameEventEvent(
                _eventState.slice,
                gameEventID,
                gameEventName,
                gameEventType,  
                gameEventStartTime,
                gameEventEndTime,     
                gameEventDuration,
                dollarPerPoint,
                pointsPerWatt,
                pointsPerPercent
                );
    }

  function AddGameResult (
        string memory gamePlayerID,   
        string memory gameEventID, 
        address gamePlayerAddress,   
        string memory averagePowerInWatts,
        string memory baselineAveragePowerInWatts,
        string memory deltaAveragePowerInWatts,
        string memory percentPoints,
        string memory wattPoints,
        string memory totalPointsAwarded,
        string memory awardValue
        )     public  
    { //onlyOwner

    
        GameResultLocals memory locals;
        //   bytes32 eventHash;
        //   bytes32 resultHash;    
        //   uint eventIndex;
        //   uint resultIndex;        
     
        //hash the crucial info to get a unique id
        //bytes32 id = keccak256(abi.encodePacked(_name, _description, _accessPath, _creationTime));

        locals.resultHash = sha256 (abi.encodePacked(gamePlayerID,gameEventID));
        locals.eventHash = sha256 (abi.encodePacked(gameEventID));

        //require that the match be unique (not already added)
        require(!GameResultExists(locals.resultHash));
        
        locals.gameResult.gameResultSignature = locals.resultHash;
        locals.gameResult.gamePlayerID = gamePlayerID;
        locals.gameResult.gameEventID = gameEventID;   
        locals.gameResult.gamePlayerAddress = gamePlayerAddress;
        locals.gameResult.averagePowerInWatts = averagePowerInWatts;
        locals.gameResult.baselineAveragePowerInWatts = baselineAveragePowerInWatts;
        locals.gameResult.deltaAveragePowerInWatts = deltaAveragePowerInWatts;
        locals.gameResult.percentPoints = percentPoints;
        locals.gameResult.wattPoints = wattPoints;
        locals.gameResult.totalPointsAwarded = totalPointsAwarded;
        locals.gameResult.awardValue = awardValue;
        locals.gameResult.status = "unconfirmed";

        _gameResults.push(locals.gameResult);
        locals.resultIndex = _gameResults.length - 1;
        _gameResultIDHashToIndex[locals.resultHash] = locals.resultIndex ;

        locals.eventIndex = _gameEventIDHashToIndex[locals.eventHash];
 
        _resultState.count++;
        _resultState.slice = _resultState.count/_sliceSize;

        ResultCount = _resultState.count;

        locals.gamePlayerIDIdx = sha256 (abi.encodePacked(gamePlayerID));

        emit GameResultEvent(
                    _resultState.slice,
                    locals.gamePlayerIDIdx,
                    locals.gameResult.gamePlayerID,
                    locals.gameResult.gameEventID,
                    _gameEvents[locals.eventIndex].gameEventStartTime,
                    locals.gameResult.averagePowerInWatts,
                    locals.gameResult.baselineAveragePowerInWatts,
                    locals.gameResult.deltaAveragePowerInWatts,
                    locals.gameResult.percentPoints,
                    locals.gameResult.wattPoints,
                    locals.gameResult.totalPointsAwarded,
                    locals.gameResult.awardValue
                    );

        emit GameCombinedEventResultEvent(
                    _resultState.slice,
                    locals.gamePlayerIDIdx,
                    locals.gameResult.gamePlayerID,
                    locals.gameResult.gameEventID,
                    _gameEvents[locals.eventIndex].gameEventStartTime,
                    _gameEvents[locals.eventIndex].gameEventDuration,
                    _gameEvents[locals.eventIndex].pointsPerWatt,
                    locals.gameResult.averagePowerInWatts,
                    locals.gameResult.baselineAveragePowerInWatts,
                    locals.gameResult.deltaAveragePowerInWatts,
                    locals.gameResult.wattPoints,
                    locals.gameResult.awardValue
                    );

    }

    function UpdateResultsStatus(string memory resultID, 
                                string memory status) public onlyOwner 
    {
        //STUB
        //require(msg.sender == owner);
        //bytes32 resultIDBytes = StringToBytes32(resultID);
        //string memory myStatus = status;
        //TODO pop result, update status, push result
    }

    function UpdatePlayerStatus(string memory playerID, 
                                string memory status) public onlyOwner 
    {
        //STUB
        //require(msg.sender == owner);
        //bytes32 playerIDBytes = StringToBytes32(playerID);
        //string memory myStatus = status;
        //TODO pop player, update status, push player
    }

 
 ///////////////////////////
//   function logAllPlayers() public {
//        // bytes32[] memory output = new bytes32[](_gamePlayers.length);

//         //get all ids
//         if (_gamePlayers.length > 0) {
//             //uint index = 0;
//             for (uint n = _gamePlayers.length; n > 0; n--) {
//                 emit GamePlayerEvent(
//                     _gamePlayers[n-1].gamePlayerID,
//                     _gamePlayers[n-1].gamePlayerSignature,
//                     _gamePlayers[n-1].dataConnectionString,
//                     _gamePlayers[n-1].gamePlayerAddress,
//                     _gamePlayers[n-1].active
//                     );  
//                 //output[index++] = _gamePlayers[n-1].gamePlayerSignature;
//             }
//         }
//     }

//     function logAllEvents() public view returns (string[] memory) {
//         string[] memory output = new string[](_gameEvents.length);

//         //get all ids
//         if (_gameEvents.length > 0) {
//             uint index = 0;
//             for (uint n = _gameEvents.length; n > 0; n--) {
//                 output[index++] = _gameEvents[n-1].gameEventID;
//             }
//         }
//         return output;
//     }

// function logAllResults() public view returns (bytes32[] memory) {
//         bytes32[] memory output = new bytes32[](_gameResults.length);

//         //get all ids
//         if (_gameResults.length > 0) {
//             uint index = 0;
//             for (uint n = _gameResults.length; n > 0; n--) {
//                 output[index++] = _gameResults[n-1].gameResultID;
//             }
//         }
//         return output;
//     }


// /////////////////////////
//     function getAllPlayers() public view returns (string[] memory) {
//         string[] memory output = new string[](_gamePlayers.length);

//         //get all ids
//         if (_gamePlayers.length > 0) {
//             uint index = 0;
//             for (uint n = _gamePlayers.length; n > 0; n--) {
//                 output[index++] = _gamePlayers[n-1].gamePlayerID;
//             }
//         }
//         return output;
//     }

//     function getAllEvents() public view returns (string[] memory) {
//         string[] memory output = new string[](_gameEvents.length);

//         //get all ids
//         if (_gameEvents.length > 0) {
//             uint index = 0;
//             for (uint n = _gameEvents.length; n > 0; n--) {
//                 output[index++] = _gameEvents[n-1].gameEventID;
//             }
//         }
//         return output;
//     }

//     function getAllResults() public view returns (bytes32[] memory) {
//         bytes32[] memory output = new bytes32[](_gameResults.length);

//         //get all ids
//         if (_gameResults.length > 0) {
//             uint index = 0;
//             for (uint n = _gameResults.length; n > 0; n--) {
//                 output[index++] = _gameResults[n-1].gameResultID;
//             }
//         }
//         return output;
//     }
//////////////////////////////////



    /// notice can be used by a client contract to ensure that they've connected to this contract interface successfully
    /// @return true, unconditionally
    function testConnection() public pure returns (bool) 
    {
        return true;
    }



    /// notice gets the address of this contract
    /// @return address
    function getAddress() public view returns (address) 
    {
        return address(this);
    }


 
    /// notice for testing
    function addTestData() external onlyOwner 
    {
        //addDataItem("ElectricDemand", "Electricity Demand for 13470", "ThingSpeak", "Now");
        // addDataItem("Macquiao vs. Payweather", "Macquiao|Payweather", 2, DateLib.DateTime(2018, 8, 15, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Pacweather vs. Macarthur", "Pacweather|Macarthur", 2, DateLib.DateTime(2018, 9, 3, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Macarthur vs. Truman", "Macarthur|Truman", 2, DateLib.DateTime(2018, 9, 3, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Macaque vs. Pregunto", "Macaque|Pregunto", 2, DateLib.DateTime(2018, 9, 21, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Farsworth vs. Wernstrom", "Farsworth|Wernstrom", 2, DateLib.DateTime(2018, 9, 29, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Fortinbras vs. Hamlet", "Fortinbras|Hamlet", 2, DateLib.DateTime(2018, 10, 10, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Foolicle vs. Pretendo", "Foolicle|Pretendo", 2, DateLib.DateTime(2018, 11, 11, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Parthian vs. Scythian", "Parthian|Scythian", 2, DateLib.DateTime(2018, 11, 12, 0, 0, 0, 0, 0).toUnixTimestamp());
    }

    // function StringtoAddress(string memory _a) internal pure returns (address _parsedAddress) {
    //     bytes memory tmp = bytes(_a);
    //     uint160 iaddr = 0;
    //     uint160 b1;
    //     uint160 b2;
    //     for (uint i = 2; i < 2 + 2 * 20; i += 2) {
    //         iaddr *= 256;
    //         b1 = uint160(uint8(tmp[i]));
    //         b2 = uint160(uint8(tmp[i + 1]));
    //         if ((b1 >= 97) && (b1 <= 102)) {
    //             b1 -= 87;
    //         } else if ((b1 >= 65) && (b1 <= 70)) {
    //             b1 -= 55;
    //         } else if ((b1 >= 48) && (b1 <= 57)) {
    //             b1 -= 48;
    //         }
    //         if ((b2 >= 97) && (b2 <= 102)) {
    //             b2 -= 87;
    //         } else if ((b2 >= 65) && (b2 <= 70)) {
    //             b2 -= 55;
    //         } else if ((b2 >= 48) && (b2 <= 57)) {
    //             b2 -= 48;
    //         }
    //         iaddr += (b1 * 16 + b2);
    //     }
    //     return address(iaddr);
    // }


    // function StringToBytes32(string memory source) internal pure returns (bytes32 result) {
    //     bytes memory tempEmptyStringTest = bytes(source);
    //     if (tempEmptyStringTest.length == 0) {
    //         return 0x0;
    //     }
    //     assembly {
    //         result := mload(add(source, 32))
    //     }
    // }

    function Bytes32ToString(bytes32 x) internal pure returns (string memory)  {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
        bytes1 char = bytes1(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[charCount] = char;
            charCount++;
        }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (uint j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
    }


    function StringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }


    function UintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    // function StringCompare(string memory a, string memory b) internal pure returns (bool) {
    // //function HashCompareWithLengthCheck(string a, string b) internal returns (bool) {
    //     if(bytes(a).length != bytes(b).length) {
    //         return false;
    //     } else {
    //         return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    //     }
    // }

  /// destroy the contract and reclaim the leftover funds.
    function kill() public onlyOwner 
    {
        //require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }
}
