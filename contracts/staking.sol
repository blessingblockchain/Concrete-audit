// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vault} from "./Vault.sol";

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Staking {
    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    uint32 private _stakingDuration = 60 days;

    IERC20 private _token;

    Vault private _vault;

    // artist => user => Stake tracker
    mapping(address => Stake) private _stakes;

    // artist => totalStakes tracker
    mapping(address => uint256) private _artistTotalStakes;

    event StakeDeposited(
        address indexed artist,
        uint256 amount
    );

    event StakeWithdrawn(
        address indexed artist,
        uint256 amount
    );

    // Constructor

    constructor(address _tokenAddress, address _vaultAddress) {
        _token = IERC20(_tokenAddress);

        _vault = Vault(_vaultAddress);
    }

    // we need to ensure that address(this) has been set as a rewardDelegator in Vault so that users can earn rewards after staking for `stakingduration`
    modifier isRewardDelegator() {
        require(
            _vault.rewardDelegator(address(this)),
            "Deployer should set address(this) to be a reward delegator in Vault contract"
        );

        _;
    }

    function stakingDuration() public view returns (uint256) {
        return _stakingDuration;
    }

    function stakesInfo(address artist) public view returns (uint256, uint256) {
        Stake memory userArtistStake = _stakes[artist];
        return (userArtistStake.amount, userArtistStake.timestamp);
    }

    function artistTotalStakes(address artist) public view returns (uint256) {
        return _artistTotalStakes[artist];
    }

    /**
        @dev stakeToken
        after msg.sender approves this contract to spend `amount` of their ERC20, calls this function to stake the approved `amount` of tokens
    */
    function stakeToken(address artist, uint256 amount) external isRewardDelegator {
        require(amount > 0, "Amount must be greater than 0");

        require(
            _token.transferFrom(artist, address(this), amount),
            "Amount not approved by msg.sender for contract to transfer"
        );

        _stakes[artist] = Stake(amount, block.timestamp);

        emit StakeDeposited(artist, amount);
    }

    function withdrawToken(address artist) external {
        Stake memory userStake = _stakes[artist];

        require(userStake.amount > 0, "No stake found");

        require(
            block.timestamp >= userStake.timestamp + _stakingDuration,
            "Stake is locked"
        );

        uint256 amount = userStake.amount;

        _stakes[artist].amount = 0;

        emit StakeWithdrawn(artist, amount);

        require(_token.transfer(msg.sender, amount), "Token transfer failed");

        // user earn 1% of staked amount as rewardToken
        uint256 depositBasedReward = (10 * amount) / 100;

        _vault.sendReward(msg.sender, depositBasedReward);
    }
}
