// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

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

contract Staking {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    IERC20 public loriaToken;

    event Staked(address user, uint amount, uint index);
    event Withdrawn(address user, uint amount);
    event RewardPaid(address user, uint amount);
    event RecoverStaking(address user, uint amount);
    event Claimed(address user, uint amount);

    uint public DogeAPY = 2;
    uint public LoriaAPY = 2;
    uint public DogeElig = 15;
    uint public LoriaElig = 30;
    uint private day = 24 * 3600;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint private _totalSupply;
    uint256 private _totalStakedUserCount;
    address[] private _stakedAddressList;
    address private owner;
    
    struct StakingItem {
        uint _initBalance;
        uint _period;
        uint _rate;
        uint _eli;
        uint _claimedDoge;
        uint _claimedLoria;
        uint256 _updated_at;
        uint256 _created_at;
        bool _isRewarded;
    }

    mapping(address => StakingItem[]) private _stakingList;
    
    constructor(address _stakingToken, address _loriaToken ,  address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        loriaToken = IERC20(_loriaToken);
        rewardsToken = IERC20(_rewardsToken);
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function stake(uint _amount, uint _period) external {
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        _totalSupply += _amount;
        bool flag = false;
        if (_stakingList[msg.sender].length > 0) {
            uint lastIdx = _stakingList[msg.sender].length - 1;
            if (_stakingList[msg.sender][lastIdx]._rate == DogeAPY) {
                if (_stakingList[msg.sender][lastIdx]._eli == DogeElig) {
                    _stakingList[msg.sender][lastIdx]._initBalance += _amount;
                    _stakingList[msg.sender][lastIdx]._created_at = block.timestamp;
                    _stakingList[msg.sender][lastIdx]._isRewarded = false;
                }
                else flag = true;
            }
            else flag = true;
        }
        else flag = true;

        if (flag) {
            StakingItem memory item = StakingItem({
                _initBalance: _amount,
                _created_at: block.timestamp,
                _updated_at: block.timestamp,
                _period: _period,
                _rate: DogeAPY,
                _claimedDoge: 0,
                _claimedLoria: 0,
                _eli: DogeElig,
                _isRewarded: false
            });
            _stakingList[msg.sender].push(item);
        }

        uint index = _stakingList[msg.sender].length - 1;
        receiveReward(index, _amount);
        emit Staked(msg.sender, _amount, index);
    }

    function withdraw(uint256 balance) external {
        rewardsToken.transferFrom(msg.sender,address(this), balance);
        StakingItem[] memory item = _stakingList[msg.sender];
        uint timestamp = block.timestamp;
        for (uint i = 0; i < item.length; i ++) {
            if (timestamp - _stakingList[msg.sender][i]._created_at < _stakingList[msg.sender][i]._eli * 1 days) {
                balance -= _stakingList[msg.sender][i]._initBalance;
            }
        }
        if (balance > 0) stakingToken.transfer(msg.sender, balance);
        delete _stakingList[msg.sender];
    }
    
    function claim(uint idx) external {
        uint diff = block.timestamp - _stakingList[msg.sender][idx]._updated_at;
        if ( diff > 0) {
            uint _dogeRewards = _stakingList[msg.sender][idx]._initBalance * _stakingList[msg.sender][idx]._rate / 100;
            uint _loriaRewards = _stakingList[msg.sender][idx]._initBalance * LoriaAPY / (100 * 1000);
            stakingToken.transfer(msg.sender, _dogeRewards);
            if (_loriaRewards > 0) {
                loriaToken.transfer(msg.sender, _loriaRewards);
                _stakingList[msg.sender][idx]._claimedLoria += _loriaRewards;
            }
            _stakingList[msg.sender][idx]._updated_at = block.timestamp;
            _stakingList[msg.sender][idx]._claimedDoge += _dogeRewards;
            emit Claimed(msg.sender, _dogeRewards);
        }
    }
    
    function multipleClaim() external {
        uint dogeClaim = 0;
        uint loriaClaim = 0;
        uint timestamp = block.timestamp;
        StakingItem[] memory item = _stakingList[msg.sender];
        for (uint i = 0; i < item.length; i ++) {
            uint diff = timestamp - _stakingList[msg.sender][i]._created_at;
            // if ( diff >= _stakingList[msg.sender][i]._eli * 1 days) {
            if ( diff >= 0) {
                // uint duration = _stakingList[msg.sender][i]._eli * 24 * 3600;
                // uint count = diff / duration;
                uint count = 1;
                uint dogeReward = _stakingList[msg.sender][i]._initBalance * _stakingList[msg.sender][i]._rate / 100 * count;
                uint loriaReward = _stakingList[msg.sender][i]._initBalance * LoriaAPY / (100 * 1000);
                dogeClaim += dogeReward; loriaClaim += loriaReward;
                _stakingList[msg.sender][i]._claimedLoria += loriaReward;
                _stakingList[msg.sender][i]._claimedDoge += dogeReward;
            }
        }
        stakingToken.transfer(msg.sender, dogeClaim);
        if (loriaClaim > 0) loriaToken.transfer(msg.sender, loriaClaim);
    }

    function recoverToken(uint amount) external onlyOwner {
        stakingToken.transfer(owner, amount);
        emit RecoverStaking(owner, amount);
    }

    function setDogeAPY(uint _apy) external onlyOwner {
        DogeAPY = _apy;
    }
    
    function setDogeElig(uint _day) external onlyOwner {
        require(_day > 0, "Date error");
        DogeElig = _day;
    }

    function getStakedList() external view returns(StakingItem[] memory list) {
        return _stakingList[msg.sender];
    }

    function getDogeAPY() external view returns(uint reward) {
        return DogeAPY;
    }

    function getDogeElig() external view returns(uint) {
        return DogeElig;
    }

    function receiveReward(uint _idx, uint _amount) private {
        require(!_stakingList[msg.sender][_idx]._isRewarded, "You have received!");
        _stakingList[msg.sender][_idx]._isRewarded = true;
        rewardsToken.transfer(msg.sender, _amount);
    }
}