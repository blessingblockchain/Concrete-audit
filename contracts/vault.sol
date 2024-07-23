// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Governed} from "./Governed.sol";

contract Vault is Governed {
    mapping(address => bool) internal _rewardDelegators;

    // reward token which vault would hold some balance of
    IERC20 _token;

    event RewardDelegatorAdded(address indexed account);
    event RewardDelegatorRemoved(address indexed account);
    event RewardTransfer(
        address indexed to,
        uint256 indexed amount,
        address indexed delegator
    );

    constructor(address _rewardToken) {
        _token = IERC20(_rewardToken);

        _initialize(msg.sender);

        _rewardDelegators[msg.sender] = true;
    }

    modifier onlyRewardDelegator() {
        require(
            _rewardDelegators[msg.sender],
            "Only approved rewardDelegator can call this function"
        );

        _;
    }

    function rewardDelegator(address _account) external view returns (bool) {
        return _rewardDelegators[_account];
    }

    function addRewardDelegator(address _delegator) external onlyGovernor {
        emit RewardDelegatorAdded(_delegator);

        _rewardDelegators[_delegator] = true;
    }

    function removeRewardDelegator(address _delegator) external onlyGovernor {
        emit RewardDelegatorRemoved(_delegator);

        _rewardDelegators[_delegator] = false;
    }

    function sendReward(
        address _recipient,
        uint256 _amount
    ) external onlyRewardDelegator {
        require(
            _token.balanceOf(address(this)) > _amount,
            "Vault is drained. Fill-up to payout reward"
        );

        emit RewardTransfer(_recipient, _amount, msg.sender);

        _token.transfer(_recipient, _amount);
    }
}