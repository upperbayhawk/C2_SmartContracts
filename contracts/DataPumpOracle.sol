// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;
import "./C2COwnable.sol";
import "./DateLib.sol";


/// @title DataPumpOracle
/// @author John R. Kosinski
/// notice Collects and provides information on boxing matches and their outcomes
contract DataPumpOracle is C2COwnable {
    using DateLib for DateLib.DateTime;

    //defines a DataItem along with its outcome
    struct Oracle {
        string name;            //human-friendly name
        string namehash;    //name in external system
        string description;    //name in external system
        string lastPingTime;      //a delimited string of participant names
        string creationTime;    //a delimited string of participant names
    }


    //defines a DataItem along with its outcome
    struct DataItem {
        bytes32 id;             //unique id
        string name;            //human-friendly name
        string description;    //name in external system
        string externalName;    //name in external system
        string value;           //value of dataa delimited string of participant names
        string externalValue;   //a delimited string of participant names
        string quality;         //a delimited string of participant names
        string updateTime;      //a delimited string of participant names
        string serverTime;      //a delimited string of participant names
        string creationTime;    //a delimited string of participant names
        string accessPath;      //path to value
        // uint date;              //GMT timestamp of date of contest
        DataItemOutcome outcome;   //the outcome (if decided)
    //    int8 winner;            //index of the participant who is the winner
    }
 
   //possible match outcomes
    enum DataItemOutcome {
        Pending,    //match has not been fought to decision
        Underway,   //match has started & is underway
        Draw,       //anything other than a clear winner (e.g. cancelled)
        Decided     //index of participant who is the winner
    }

    event OraclePingEvent(
        string indexed oracleNameIdx,
        string oracleName,
        uint seqNumber,
        address oracleAddress,
        string time
    );

    event OracleDockEvent(
        string indexed oracleNameIdx,
        string oracleName,
        uint seqNumber,
        address oracleAddress,
        string time
    );

    event OracleUndockEvent(
        string indexed oracleNameIdx,
        string oracleName,
        uint seqNumber,
        address oracleAddress,
        string time
    );

    event OracleGetDataEvent(
        string indexed oracleNameIdx,
        string oracleName,
        uint seqNumber,
        address oracleAddress,
        string time
    );


    Oracle[] oracle;
    mapping(bytes32 => uint) oracleIdToIndex;
    DataItem[] data;
    mapping(bytes32 => uint) dataItemIdToIndex;
    
    string public OracleName;
    /// External State Variables
    bool public HasDataReadyFlag = false;
    bool public HasDockedOracleFlag = false;

    /// construction of contract
    constructor()  {
        OracleName = "Upperbay Systems DataPump Oracle";
    }


    /// notice returns the array index of the match with the given id
    /// @dev if the match id is invalid, then the return value will be incorrect and may cause error; you must call matchExists(_dataItemID) first!
    /// @param _dataItemId the match id to get
    /// @return an array index
    function _getDataItemIndex(bytes32 _dataItemId) private view returns (uint) {
        return dataItemIdToIndex[_dataItemId]-1;
    }
  

  /// notice determines whether a match exists with the given id
    /// @param _dataItemId the match id to test
    /// @return true if match exists and id is valid
    function dataItemExists(bytes32 _dataItemId) public view returns (bool) {
        if (data.length == 0)
            return false;
        uint index = dataItemIdToIndex[_dataItemId];
        return (index > 0);
    }


    /// notice puts a new pending match into the blockchain
    /// @param _name descriptive name for the match (e.g. Pac vs. Mayweather 2016)
    /// @param _description |-delimited string of participants names (e.g. "Manny Pac|Floyd May")
    /// @param _accessPath number of participants
    /// @param _creationTime date set for the match
    /// @return the unique id of the newly created match
    function addDataItem(string memory _name,
        string memory _description,
        string memory _accessPath,
        string memory _creationTime) onlyOwner public returns (bytes32) {

        //hash the crucial info to get a unique id
        //bytes32 id = keccak256(abi.encodePacked(_name, _description, _accessPath, _creationTime));
        //bytes32 id_sha = sha256 (abi.encodePacked(_name));
        bytes32 id = keccak256(abi.encodePacked(_name));

        //require that the match be unique (not already added)
        require(!dataItemExists(id));
        
        DataItem memory dataItem;
        dataItem.name = _name;
        dataItem.description = _description;
        dataItem.accessPath = _accessPath;
        dataItem.creationTime = _creationTime;
        dataItem.externalValue = "null";
        dataItem.externalName = "null";
        dataItem.value = "null";
        dataItem.quality = "null";
        dataItem.creationTime = "null";
        dataItem.updateTime = "null";
        dataItem.serverTime = "null";
        dataItem.outcome = DataItemOutcome.Pending;

        // newIndex = data.push(dataItem) - 1;
        data.push(dataItem);
        uint newIndex = data.length - 1;
        dataItemIdToIndex[id] = newIndex;
        
        //return the unique id of the new match
        return id;
    }



  /// notice sets the outcome of a predefined match, permanently on the blockchain
    /// @param _dataItemId unique id of the match to modify
    /// @param _outcome outcome of the match
    /// @param _winner winner
    // function declareDataOutcome(bytes32 _dataItemId, DataItemOutcome _outcome, int8 _winner) onlyOwner external {

    //     //require that it exists
    //     require(dataItemExists(_dataItemId));

    //     //get the match
    //     uint index = _getDataItemIndex(_dataItemId);
    //     DataItem storage theDataItem = data[index];

    //     if (_outcome == DataItemOutcome.Decided)
    //         require(_winner >= 0 && theDataItem.participantCount > uint8(_winner));

    //     //set the outcome
    //     theDataItem.outcome = _outcome;
        
    //     //set the winner (if there is one)
    //     if (_outcome == DataItemOutcome.Decided)
    //         theDataItem.winner = _winner;
    // }


 
    /// notice gets the unique ids of all pending matches, in reverse chronological order
    /// @return an array of unique match ids
    function getPendingDataItems() public view returns (bytes32[] memory) {
        uint count = 0;

        //get count of pending matches
        for (uint i = 0; i < data.length; i++) {
            if (data[i].outcome == DataItemOutcome.Pending)
                count++;
        }

        //collect up all the pending matches
        bytes32[] memory output = new bytes32[](count);

        if (count > 0) {
            uint index = 0;
            for (uint n = data.length; n > 0; n--) {
                if (data[n-1].outcome == DataItemOutcome.Pending)
                    output[index++] = data[n-1].id;
            }
        }
        return output;
    }




   /// notice gets the unique ids of dataItems, pending and decided, in reverse chronological order
    /// @return an array of unique match ids
    function getAllDataItems() public view returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](data.length);

        //get all ids
        if (data.length > 0) {
            uint index = 0;
            for (uint n = data.length; n > 0; n--) {
                output[index++] = data[n-1].id;
            }
        }
        
        return output;
    }



   /// notice gets the specified match
    /// @param _dataItemId the unique id of the desired match
    /// @return match data of the specified match
    function getDataItem(bytes32 _dataItemId) public view returns (DataItem memory) {
        DataItem memory dataItem;
        //get the match
        if (dataItemExists(_dataItemId)) {
            DataItem storage theDataItem = data[_getDataItemIndex(_dataItemId)];
            return (theDataItem);
        }
        else {
            return (dataItem);
        }
    }

    /// notice gets the specified match
    /// @param _dataItemId the unique id of the desired match
    /// @return match data of the specified match
    function getDataItemValue(bytes32 _dataItemId) public view returns (string memory) {
        //get the match
        if (dataItemExists(_dataItemId)) {
            DataItem storage theDataItem = data[_getDataItemIndex(_dataItemId)];
            return (theDataItem.value);
        }
        else {
            return("null");
        }
    }

    /// notice gets the specified match
    /// @param _dataItemId the unique id of the desired match
    /// @param _value the unique id of the desired match
    /// @return match data of the specified match
    function setDataItemValueById(bytes32 _dataItemId, string memory _value) public payable returns (string memory) {
        //get the match
        if (dataItemExists(_dataItemId)) {
            DataItem storage theDataItem = data[_getDataItemIndex(_dataItemId)];
            theDataItem.externalValue = _value;
            theDataItem.value = _value;
            return (theDataItem.value);
        }
        else {
            return("null");
        }
    }


    /// notice gets the specified match
    /// @param _name the unique id of the desired match
    /// @param _value the unique id of the desired match
    /// @return match data of the specified match
    function setDataItemValueByName(string memory _name, string memory _value) public payable returns (string memory) {
        //get the match
        bytes32 id = keccak256(abi.encodePacked(_name));
        if (dataItemExists(id)) {
            DataItem storage theDataItem = data[_getDataItemIndex(id)];
            theDataItem.externalValue = _value;
            theDataItem.value = _value;
            return (theDataItem.value);
        }
        else {
            return("null");
        }
    }



   /// notice gets the specified match
    /// @param _oracleName the unique id of the desired match
    /// @param _seqNumber the unique id of the desired match
    /// @param _oracleAddress the unique id of the desired match
    /// @return match data of the specified match
    function dockOracle(string memory _oracleName, string memory _oracleNameHash, uint _seqNumber, address _oracleAddress) onlyOwner public payable returns (string memory) {
        
        Oracle memory myOracle;

        string memory oracleNameIdx = _oracleName;
        string memory oracleName = _oracleName;
        uint seqNumber = _seqNumber;
        address oracleAddress = _oracleAddress;
        string memory time = "now";
        HasDockedOracleFlag = true;

        bytes32 id_sha = sha256 (abi.encodePacked(_oracleName));
        myOracle.name = _oracleName;
        myOracle.namehash = _oracleNameHash;
        myOracle.description = "null";
        myOracle.lastPingTime = "null";
        myOracle.creationTime = "null";
        
        oracle.push(myOracle);
        uint newIndex = oracle.length - 1;
        oracleIdToIndex[id_sha] = newIndex;

        emit OracleDockEvent(oracleNameIdx, oracleName, seqNumber, oracleAddress, time);
        return(oracleName);
    }


  /// notice gets the specified match
    /// @param _oracleName the unique id of the desired match
    /// @param _seqNumber the unique id of the desired match
    /// @param _oracleAddress the unique id of the desired match
    /// @return match data of the specified match
    function undockOracle(string memory _oracleName, uint _seqNumber, address _oracleAddress) onlyOwner public payable returns (string memory) {
        
        string memory oracleNameIdx = _oracleName;
        string memory oracleName = _oracleName;
        uint seqNumber = _seqNumber;
        address oracleAddress = _oracleAddress;
        string memory time = "now";
        HasDockedOracleFlag = false;

        emit OracleUndockEvent(oracleNameIdx, oracleName, seqNumber, oracleAddress, time);
        return(oracleName);
    }

    /// notice gets the specified match
    /// @param _oracleName the unique id of the desired match
    /// @param _seqNumber the unique id of the desired match
    /// @param _oracleAddress the unique id of the desired match
    /// @return match data of the specified match
    function pingOracle(string memory _oracleName, uint _seqNumber, address _oracleAddress) onlyOwner public payable returns (string memory) {
        
        string memory oracleNameIdx = _oracleName;
        string memory oracleName = _oracleName;
        uint seqNumber = _seqNumber;
        address oracleAddress = _oracleAddress;
        string memory time = "now";

        emit OraclePingEvent(oracleNameIdx, oracleName, seqNumber, oracleAddress, time);
        return(oracleName);
    }





 /// notice gets the most recent match or pending match
    /// @param _pending if true, will return only the most recent pending match; otherwise, returns the most recent match either pending or completed
    /// @return match data
    function getMostRecentDataItem(bool _pending) public view returns (DataItem memory){

        bytes32 dataItemId = 0;
        bytes32[] memory ids;

        if (_pending) {
            ids = getPendingDataItems();
        } else {
            ids = getAllDataItems();
        }
        if (ids.length > 0) {
            dataItemId = ids[0];
        }
        
        //by default, return a null match
        return getDataItem(dataItemId);
    }



    /// notice can be used by a client contract to ensure that they've connected to this contract interface successfully
    /// @return true, unconditionally
    function testConnection() public pure returns (bool) {
        return true;
    }



    /// notice gets the address of this contract
    /// @return address
    function getAddress() public view returns (address) {
        return address(this);
    }


 
    /// notice for testing
    function addTestData() external onlyOwner {
        addDataItem("ElectricDemand", "Electricity Demand for 13470", "ThingSpeak", "Now");
        // addDataItem("Macquiao vs. Payweather", "Macquiao|Payweather", 2, DateLib.DateTime(2018, 8, 15, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Pacweather vs. Macarthur", "Pacweather|Macarthur", 2, DateLib.DateTime(2018, 9, 3, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Macarthur vs. Truman", "Macarthur|Truman", 2, DateLib.DateTime(2018, 9, 3, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Macaque vs. Pregunto", "Macaque|Pregunto", 2, DateLib.DateTime(2018, 9, 21, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Farsworth vs. Wernstrom", "Farsworth|Wernstrom", 2, DateLib.DateTime(2018, 9, 29, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Fortinbras vs. Hamlet", "Fortinbras|Hamlet", 2, DateLib.DateTime(2018, 10, 10, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Foolicle vs. Pretendo", "Foolicle|Pretendo", 2, DateLib.DateTime(2018, 11, 11, 0, 0, 0, 0, 0).toUnixTimestamp());
        // addDataItem("Parthian vs. Scythian", "Parthian|Scythian", 2, DateLib.DateTime(2018, 11, 12, 0, 0, 0, 0, 0).toUnixTimestamp());
    }



  /// destroy the contract and reclaim the leftover funds.
    function kill() public onlyOwner {
        //require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }}
