// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface DogeCoin {
    function mint(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
}

contract MSDogeSig {
    DogeCoin public token;

    struct RequestStruct {
        bool isActive;
        bool isClosed;
        bool isSent;
        address createdBy;
        address to;
        uint256 value;
        uint256 index;
    }

    struct AirDropStruct {
        address addresses;
        uint256 balances;
    }
    
    mapping(address => RequestStruct[]) public transferList;
    mapping(address => AirDropStruct[]) public airDropList;

    RequestStruct public burnRequest;
    
    mapping(address => bool) public owners;
    address[] public ownArray;
    mapping(address => uint256) transferedAmount;
    
    modifier onlyOwners() {
        require(owners[msg.sender]);
        _;
    }


    function setTokenAddress(address tokenAddress) private onlyOwners {
        token = DogeCoin(tokenAddress);
    }

    constructor(address[] memory _owners, address tokenAddress) {
        require(_owners.length == 3, "Owners are not 3 addresses" );
        for (uint i = 0; i < _owners.length; i ++) owners[_owners[i]] = true;
        setTokenAddress(tokenAddress);
    }

    // start transfer part
    function newTransferRequest(address to, uint256 value) public onlyOwners {
        RequestStruct memory transferRequest = RequestStruct({
            to: to,
            value: value,
            isClosed: false,
            isSent: false,
            isActive: true,
            index: transferList[msg.sender].length,
            createdBy: msg.sender
        });
        
        transferList[msg.sender].push(transferRequest);
    }

    function getRequestLength() public view returns(uint) {
        return transferList[msg.sender].length;    
    }
    
    function getTransferItem(uint idx) public view returns(RequestStruct memory item) {
        return transferList[msg.sender][idx];
    }
    
    function approveTransferRequest(uint idx) public onlyOwners {
        require(transferList[msg.sender][idx].isActive);
        sendTransferRequest(idx);
    }

    function approveTransferListRequest(RequestStruct[] memory list) public onlyOwners {
        for (uint i = 0; i < list.length; i ++) {
            approveTransferRequest(list[i].index);
        }
    }
    
    function declineTransferRequest(uint idx) public onlyOwners {
        require(transferList[msg.sender][idx].isActive);
        closeTransferRequest(idx, false);
    }

    function sendTransferRequest(uint idx) private onlyOwners {
        require(transferList[msg.sender][idx].isActive);
        transferList[msg.sender][idx].isActive = false;
        token.transferFrom(msg.sender, transferList[msg.sender][idx].to, transferList[msg.sender][idx].value);
        transferedAmount[msg.sender] += transferList[msg.sender][idx].value;
        closeTransferRequest(idx, true);
    }
    
    function closeTransferRequest(uint idx, bool status) private onlyOwners {
        require(transferList[msg.sender][idx].isActive);
        transferList[msg.sender][idx].isActive = false;
        transferList[msg.sender][idx].isClosed = true;
        transferList[msg.sender][idx].isSent = status;
    }
    // end transfer part

    // start burn part
    function newBurnRequest(uint256 value) public onlyOwners {
        require(!burnRequest.isActive);
        uint256 ownBalance = token.balanceOf(msg.sender);
        require(value <= ownBalance);

        burnRequest = RequestStruct({
            to: msg.sender,
            value: value,
            isActive: true,
            isClosed: false,
            isSent: false,
            index: 0,
            createdBy: msg.sender
        });
    }

    function approveBurnRequest() public onlyOwners {
        require(burnRequest.isActive);
        sendBurnRequest();
    }

    function declineBurnRequest() public onlyOwners {
        require(burnRequest.isActive);
        closeBurnRequest(false);
    }

    function sendBurnRequest() private {
        token.burnFrom(msg.sender, burnRequest.value);
        closeBurnRequest(true);
    }

    function closeBurnRequest(bool status) private {
        burnRequest.isActive = false;
        burnRequest.isClosed = true;
        burnRequest.isSent = status;
    }
    // end burn part

    function airDrop(AirDropStruct[] calldata list) public onlyOwners {
        for (uint i = 0; i < list.length; i++) {
            token.transferFrom(msg.sender, list[i].addresses, list[i].balances);
            transferedAmount[msg.sender] += list[i].balances;
            airDropList[msg.sender].push(AirDropStruct(list[i].addresses, list[i].balances));
        }
    }
    
    function getTransferedAmount() public onlyOwners view returns (uint256) {
        return transferedAmount[msg.sender];
    }
    
    function getRequestList() public onlyOwners view returns (RequestStruct[] memory list) {
        return transferList[msg.sender];
    }
    
    function getBurnRequest() public view returns(RequestStruct memory item) {
        return burnRequest;
    }
    
    function getAirDropList() public onlyOwners view returns(AirDropStruct[] memory list) {
        return airDropList[msg.sender];
    }
}