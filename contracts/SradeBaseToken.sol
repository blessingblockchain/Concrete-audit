// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// .src
import {Governed} from "./Governed.sol";

contract StradeBaseToken is ERC20, Governed {
    uint8 private _decimals;
    uint256 private _totalSupply;
    

    mapping(address => bool) private _burners;
    mapping(address => bool) private _minters;

    event Approval(address indexed spender, uint256 value);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
   

    constructor(uint256 initialSupply) ERC20("StradeBaseToken", "SBTS") {
        _decimals = 18;
        _totalSupply = initialSupply;

        _initialize(msg.sender);
        addMinter(msg.sender);

        _mint(msg.sender, initialSupply);
    }

    modifier onlyBurner() {
        require(_burners[msg.sender], ERC20InvalidSender(msg.sender));
        _;
    }

    modifier onlyMinter() {
        require(_minters[msg.sender], "Only _minters");
        _;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function addBurner(address account) public onlyGovernor {
        _burners[account] = true;
    }

    function addMinter(address account) public onlyGovernor {
        _minters[account] = true;
    }

    function isBurner(address account) view public returns (bool) {
        return _burners[account];
    }

    function isMinter(address account) view public returns (bool) {
        return _minters[account];
    }

    function burn(address from, uint256 amount) external onlyBurner {
        _burn(from, amount);
        emit Transfer(from, address(0), amount);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
        emit Transfer(address(0), to, amount);
    }
}