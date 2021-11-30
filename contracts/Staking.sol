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
        uint _dogeAPY;
        uint _dogeEli;
        uint _loriaAPY;
        uint _loriaEli;
        uint _claimedDoge;
        uint _claimedLoria;
        uint256 _updated_doge;
        uint256 _updated_loria;
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
            if (_stakingList[msg.sender][lastIdx]._dogeAPY == DogeAPY && _stakingList[msg.sender][lastIdx]._dogeEli == DogeElig && _stakingList[msg.sender][lastIdx]._loriaAPY == LoriaAPY && _stakingList[msg.sender][lastIdx]._loriaEli == LoriaElig ) {
                _stakingList[msg.sender][lastIdx]._initBalance += _amount;
                _stakingList[msg.sender][lastIdx]._updated_doge = block.timestamp;
                _stakingList[msg.sender][lastIdx]._updated_loria = block.timestamp;
                _stakingList[msg.sender][lastIdx]._isRewarded = false;
            }
            else flag = true;
        }
        else flag = true;

        if (flag) {
            StakingItem memory item = StakingItem({
                _initBalance: _amount,
                _created_at: block.timestamp,
                _updated_doge: block.timestamp,
                _updated_loria: block.timestamp,
                _period: _period,
                _dogeAPY: DogeAPY,
                _dogeEli: DogeElig,
                _loriaAPY: LoriaAPY,
                _loriaEli: LoriaElig,
                _claimedDoge: 0,
                _claimedLoria: 0,
                _isRewarded: false
            });
            _stakingList[msg.sender].push(item);
        }

        uint index = _stakingList[msg.sender].length - 1;
        receiveReward(index, _amount);
        emit Staked(msg.sender, _amount, index);
    }

    function withdraw() external {
        StakingItem[] memory item = _stakingList[msg.sender];
        uint timestamp = block.timestamp;
        uint rewardBalance = 0;
        uint stakingBalance = 0;
        for (uint i = 0; i < item.length; i ++) {
            rewardBalance += _stakingList[msg.sender][i]._initBalance;
            if (timestamp - _stakingList[msg.sender][i]._created_at >= _stakingList[msg.sender][i]._dogeEli * 1 days) {
                stakingBalance += _stakingList[msg.sender][i]._initBalance;
            }
        }
        rewardsToken.transferFrom(msg.sender,address(this), rewardBalance);
        if (stakingBalance > 0) stakingToken.transfer(msg.sender, stakingBalance);
        delete _stakingList[msg.sender];
    }
    
    function claim(uint idx) public {
        uint timestamp = block.timestamp;
        uint diffDoge = timestamp - _stakingList[msg.sender][idx]._updated_doge;
        uint diffLoria = timestamp - _stakingList[msg.sender][idx]._updated_loria;
        
        if ( diffDoge >= _stakingList[msg.sender][idx]._dogeEli * 1 days) {
            uint countDoge = (diffDoge / _stakingList[msg.sender][idx]._dogeEli / day);
            uint _dogeRewards = _stakingList[msg.sender][idx]._initBalance * _stakingList[msg.sender][idx]._dogeAPY / 100 * countDoge;
            stakingToken.transfer(msg.sender, _dogeRewards);
            _stakingList[msg.sender][idx]._updated_doge = timestamp;
            _stakingList[msg.sender][idx]._claimedDoge += _dogeRewards;
        }

        if (diffLoria >= _stakingList[msg.sender][idx]._loriaEli * 1 days ) {
            uint countLoria = (diffLoria / _stakingList[msg.sender][idx]._loriaEli / day);
            uint _loriaRewards = _stakingList[msg.sender][idx]._initBalance * _stakingList[msg.sender][idx]._loriaAPY / (100 * 1000) * countLoria;
            loriaToken.transfer(msg.sender, _loriaRewards);
            _stakingList[msg.sender][idx]._updated_loria = timestamp;
            _stakingList[msg.sender][idx]._claimedLoria += _loriaRewards;
        }

    }
    
    function multipleClaim() external {
        StakingItem[] memory item = _stakingList[msg.sender];
        for (uint i = 0; i < item.length; i ++) claim(i);
    }

    function recoverToken(uint amount) external onlyOwner {
        stakingToken.transfer(owner, amount);
        emit RecoverStaking(owner, amount);
    }

    function setDogeAPY(uint _apy) external onlyOwner {
        require(_apy > 0, "APY must be greater than zero.");
        DogeAPY = _apy;
    }
    
    function setDogeElig(uint _day) external onlyOwner {
        require(_day > 0, "Date must be greater than zero.");
        DogeElig = _day;
    }

    function setLoriaAPY(uint _apy) external onlyOwner {
        require(_apy > 0, "APY must be greater than zero.");
        LoriaAPY = _apy;
    }
    
    function setLoriaElig(uint _day) external onlyOwner {
        require(_day > 0, "Date error");
        LoriaElig = _day;
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

    function getLoriaAPY() external view returns(uint reward) {
        return LoriaAPY;
    }

    function getLoriaElig() external view returns(uint) {
        return LoriaElig;
    }

    function receiveReward(uint _idx, uint _amount) private {
        require(!_stakingList[msg.sender][_idx]._isRewarded, "You have received!");
        _stakingList[msg.sender][_idx]._isRewarded = true;
        rewardsToken.transfer(msg.sender, _amount);
    }
}