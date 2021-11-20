// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface LoriaCoin {
    function mint(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
}

contract MSDogeSig {
    LoriaCoin public token;

    struct RequestStruct {
        bool isActive;
        bool isClosed;
        bool isSent;
        address to;
        uint256 value;
        uint256 index;
    }

    struct AirDropStruct {
        address addresses;
        uint256 balances;
    }
    
    RequestStruct[] public transferList;
    AirDropStruct[] public airDropList;

    RequestStruct public burnRequest;
    
    mapping(address => bool) public owners;
    address private Owner;
    address[] public ownArray;
    uint256 transferedAmount;
    
    modifier onlyOwners() {
        require(owners[msg.sender]);
        _;
    }


    function setTokenAddress(address tokenAddress) private onlyOwners {
        token = LoriaCoin(tokenAddress);
    }

    constructor(address _owner, address tokenAddress) {
        owners[_owner] = true;
        Owner = _owner;
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
            index: transferList.length
        });
        
        transferList.push(transferRequest);
    }

    function getRequestLength() public view returns(uint) {
        return transferList.length;    
    }
    
    function getTransferItem(uint idx) public view returns(RequestStruct memory item) {
        return transferList[idx];
    }
    
    function approveTransferRequest(uint idx) public onlyOwners {
        require(transferList[idx].isActive);
        sendTransferRequest(idx);
    }

    function declineTransferRequest(uint idx) public onlyOwners {
        require(transferList[idx].isActive);
        closeTransferRequest(idx, false);
    }

    function sendTransferRequest(uint idx) private {
        require(transferList[idx].isActive);
        token.transferFrom(msg.sender, transferList[idx].to, transferList[idx].value);
        transferedAmount += transferList[idx].value;
        closeTransferRequest(idx, true);
    }
    
    function closeTransferRequest(uint idx, bool status) private {
        require(transferList[idx].isActive);
        transferList[idx].isActive = false;
        transferList[idx].isClosed = true;
        transferList[idx].isSent = status;
    }
    // end transfer part

    // start burn part
    function newBurnRequest(uint256 value) public onlyOwners {
        require(!burnRequest.isActive);
        uint256 ownBalance = token.balanceOf(Owner);
        require(value <= ownBalance);

        burnRequest = RequestStruct({
            to: Owner,
            value: value,
            isActive: true,
            isClosed: false,
            isSent: false,
            index: 0
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
            uint256 balance = token.balanceOf(msg.sender);
            require (balance >= list[i].balances, "balance is not enough");
            token.transferFrom(msg.sender, list[i].addresses, list[i].balances);
            transferedAmount += list[i].balances;
            airDropList.push(AirDropStruct(list[i].addresses, list[i].balances));
        }
    }
    
    function getTransferedAmount() public view returns (uint256) {
        return transferedAmount;
    }
    
    function getRequestList() public view returns (RequestStruct[] memory list) {
        return transferList;
    }
    
    function getBurnRequest() public view returns(RequestStruct memory item) {
        return burnRequest;
    }
    
    function getAirDropList() public view returns(AirDropStruct[] memory list) {
        return airDropList;
    }
}