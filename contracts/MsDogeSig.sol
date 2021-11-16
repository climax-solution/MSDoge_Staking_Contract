// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMSDoge {
    function mint(address account, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract MSDogeSig {
    IMSDoge public token;

    struct RequestStruct {
        bool approvalsAddr;
        bool declinesAddr;
        address to;
        uint256 value;
        uint8 approvals;
        uint8 declines;
        address createdBy;
        bool isActive;
    }

    RequestStruct[] public transferList;
    RequestStruct public burnRequest;
    
    mapping(address => bool) public owners;
    address[] public ownArray;
    uint256 transferedAmount;
    
    modifier onlyOwners() {
        require(owners[msg.sender]);
        _;
    }


    function setTokenAddress(address tokenAddress) private onlyOwners {
        require(token == IMSDoge(address(0)));
        token = IMSDoge(tokenAddress);
    }

    constructor(address _owner, address contractAddress) {
        owners[_owner] = true;
        setTokenAddress(contractAddress);
    }

    // start transfer part
    function newTransferRequest(address to, uint256 value) public onlyOwners {
        RequestStruct memory transferRequest = RequestStruct(true, false, to, value, 1, 0, msg.sender, true );
        transferList.push(transferRequest);
    }

    function approveTransferRequest(uint idx) public onlyOwners {
        require(transferList[idx].isActive);
        require(!transferList[idx].approvalsAddr);

        transferList[idx].approvalsAddr = true;
        transferList[idx].approvals += 1;

        if (transferList[idx].approvals == 2) {
            sendTransferRequest(transferList[idx]);
        }
    }

    function declineTransferRequest(uint idx) public onlyOwners {
        require(transferList[idx].isActive);
        require(!transferList[idx].declinesAddr);

        transferList[idx].declinesAddr = true;
        transferList[idx].declines += 1;

        if (transferList[idx].declines == 2) {
            closeTransferRequest(transferList[idx]);
        }
    }

    function sendTransferRequest(RequestStruct memory transferItem) private {
        token.transfer(transferItem.to, transferItem.value);
        transferedAmount += transferItem.value;
        closeTransferRequest(transferItem);
    }

    function closeTransferRequest(RequestStruct memory transferItem) private pure {
        transferItem.isActive = false;
        transferItem.approvalsAddr = false;
        transferItem.declinesAddr = false;
    }
    // end transfer part

    // start burn part
    function newBurnRequest(uint256 value) public onlyOwners {
        require(!burnRequest.isActive);

        uint256 ownBalance = token.balanceOf(address(this));
        require(value <= ownBalance);

        burnRequest = RequestStruct( true, false, address(0), value, 1, 0,msg.sender, true );
    }

    function approveBurnRequest() public onlyOwners {
        require(burnRequest.isActive);
        require(!burnRequest.approvalsAddr);

        burnRequest.approvalsAddr = true;
        burnRequest.approvals += 1;

        if (burnRequest.approvals == 2) {
            sendBurnRequest();
        }
    }

    function declineBurnRequest() public onlyOwners {
        require(burnRequest.isActive);
        require(!burnRequest.declinesAddr);

        burnRequest.declinesAddr = true;
        burnRequest.declines += 1;

        if (burnRequest.declines == 2) {
            closeBurnRequest();
        }
    }

    function sendBurnRequest() private {
        token.burn(burnRequest.value);
        closeBurnRequest();
    }

    function closeBurnRequest() private {
        burnRequest.isActive = false;
        burnRequest.approvalsAddr = false;
        burnRequest.declinesAddr = false;
    }
    // end burn part
    
    function getTransferedAmount() public view returns (uint256) {
        return transferedAmount;
    }
}