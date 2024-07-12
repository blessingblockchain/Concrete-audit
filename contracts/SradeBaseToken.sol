// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// .src
import {Governed} from "./Governed.sol";

/**
 * @title StradeBaseToken
 * @dev Implementation of a custom ERC20 token with governance capabilities.
 */
contract StradeBaseToken is ERC20, Governed {
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    // Mapping to keep track of addresses that are authorized to burn tokens
    mapping(address => bool) private _burners;

    // Mapping to keep track of addresses that are authorized to mint tokens
    mapping(address => bool) private _minters;

    
    event Approval(address indexed spender, uint256 value);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
   
/**
     * @dev Initializes the token with a given supply, sets the decimals, and grants
     * the deployer the minter role.
     * @param initialSupply The initial supply of tokens.
     */
    constructor(uint256 initialSupply) ERC20("StradeBaseToken", "SBTS") {
        _decimals = 18;
        _totalSupply = initialSupply;

       // Initialize the governor and add the deployer as a minter.
        _initialize(msg.sender);
        addMinter(msg.sender);

        // Mint the initial supply of tokens to the deployer.
        _mint(msg.sender, initialSupply);
    }

     /**
     * @dev Modifier to check if the caller has the burner role.
     */
    modifier onlyBurner() {
        if(!_burners[msg.sender])
         revert ERC20InvalidSender(msg.sender);
        _;
    }

    modifier onlyMinter() {
        if(!_minters[msg.sender])
         revert ERC20InvalidSender(msg.sender);
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

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
        emit Transfer(address(0), to, amount);
    }
}