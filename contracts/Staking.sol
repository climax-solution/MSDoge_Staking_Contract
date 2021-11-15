// SPDX-License-Identifier: MIT

pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

contract Staking {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint private _totalSupply;
    uint256 private _totalStakedUserCount;
    address[] private _stakedAddressList;

    
    struct StakingItem {
        uint _balance;
        uint256 _updated_at;
        uint256 _created_at;
        uint _rate;
        bool isExisted;
    }
    mapping(address => StakingItem[]) private _stakingList;
    
    constructor(address _stakingToken, address _rewardsToken, uint _rewardRate) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        rewardRate = _rewardRate;
    }

    modifier _isExistedAccount(address account) {
        // bool _isExisted = false; uint flag;
        // for (uint i = 0; i < _stakedAddressList.length; i ++) {
        //     if (_stakedAddressList[i] == account) {
        //         _isExisted = true; flag = i;
        //     }
        // }
        // if (_isExisted) {
        //     delete _stakedAddressList[flag];
        // }
        _;
    }
    
    function stake(uint _amount) external _isExistedAccount(msg.sender){
        _totalSupply += _amount;
        _stakedAddressList.push(msg.sender);
        if (_stakingList[msg.sender].length > 0) {
            uint lastIdx = _stakingList[msg.sender].length - 1;
            if (_stakingList[msg.sender][lastIdx]._rate == rewardRate) {
                _stakingList[msg.sender][lastIdx]._balance += _amount;
                _stakingList[msg.sender][lastIdx]._created_at = block.timestamp;
            }
            else {
                _stakingList[msg.sender].push(StakingItem(_amount, block.timestamp, block.timestamp, rewardRate, true));
            }
        }
        else {
            _stakingList[msg.sender].push(StakingItem(_amount, block.timestamp, block.timestamp, rewardRate, true));
        }
        rewardsToken.transfer(msg.sender, _amount);
    }

    function withdraw(uint idx) external {
        _totalSupply -= _stakingList[msg.sender][idx]._balance;
        uint _amount = _stakingList[msg.sender][idx]._balance;
        _stakingList[msg.sender][idx]._balance = 0;
        
        if ( block.timestamp > _stakingList[msg.sender][idx]._created_at + 15 days) {
            stakingToken.transfer(msg.sender, _amount);
            delete _stakingList[msg.sender][idx];
        }

        
    }
    
    function claim(uint idx) public {
        if ( block.timestamp > _stakingList[msg.sender][idx]._updated_at + 15 days) {
            uint _reward = _stakingList[msg.sender][idx]._balance * _stakingList[msg.sender][idx]._rate / 100;
            stakingToken.transfer(msg.sender, _reward);
            _stakingList[msg.sender][idx]._updated_at = block.timestamp;
        }
    }
    
    function setRewardRate(uint _rate) external {
        rewardRate = _rate;
    }
    

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}