import {AddressLike} from "ethers";
import hre from "hardhat";
import {Staking, StradeBaseToken, Vault} from "../typechain-types";

const {expect} = require("chai");

let _token: StradeBaseToken
let _token_address: AddressLike

let _vault: Vault
let _vault_address: AddressLike

let _staking: Staking
let _staking_address: AddressLike

let owner: { address: AddressLike }
let tester: HardhatEthersSigner

describe("Token contract", function () {

    before(async () => {
        const [_owner, _tester] = await hre.ethers.getSigners();
        owner = _owner
        tester = _tester

        console.log('owner & tester: ', owner.address, tester.address)
        const StradeToken = await hre.ethers.getContractFactory("contracts/StradeBaseToken.sol:StradeBaseToken");
        _token = await StradeToken.deploy(200);
        await _token.waitForDeployment()

        _token_address = await _token.getAddress()
        console.log("Main contract deployed to:", _token_address);

        //  Deploy the vault contract
        const StradeVault = await hre.ethers.getContractFactory("contracts/vault.sol:Vault");
        _vault = await StradeVault.deploy(_token_address);
        await _vault.waitForDeployment()
        _vault_address = await _vault.getAddress();
        console.log("Vault contract deployed to:", _vault_address);

        //  Deploy the staking contract
        const StradeStaking = await hre.ethers.getContractFactory("contracts/staking.sol:Staking");
        _staking = await StradeStaking.deploy(_token_address, _vault_address);
        await _staking.waitForDeployment()
        _staking_address = await _staking.getAddress();
        console.log("Staking contract deployed to:", _staking_address);
    })

    it("Deployment should assign the total supply of tokens to the owner", async function () {
        const ownerBalance = await _token.balanceOf(owner.address);
        expect(await _token.totalSupply()).to.equal(ownerBalance);
        expect(await _token.decimals()).to.equal(18);
    });

    it('should transfer tokens between accounts', async function () {
        console.log('Transferring 50 tokens to tester...')
        await _token.transfer(tester.address, 50);
        expect(await _token.balanceOf(tester.address)).to.equal(50);
        expect(await _token.balanceOf(owner.address)).to.equal(150);

        console.log('Total supply:', await _token.balanceOf(owner.address))
        console.log('Tester balance:', await _token.balanceOf(tester.address))
    });

    it('should be able to stake tokens', async function () {
        console.log('Adding staking contract as a reward delegator...')
        await _vault.addRewardDelegator(_staking_address)
        console.log('Approving 5tokens for spend...')
        await _token.connect(tester).approve(_staking_address, 5)

        let allowance = await _token.allowance(tester.address, _staking_address);
        console.log(`Stake Allowance: ${allowance}, staking...`);

        await _staking.stakeToken(tester.address, 5);
        expect(await _token.balanceOf(tester.address)).to.equal(45);
        console.log('5 tokens staked successfully')

        console.log('Total supply:', await _token.balanceOf(owner.address))
        console.log('Tester balance:', await _token.balanceOf(tester.address))
        console.log('Staking balance: ', await _token.balanceOf(_staking_address))
    });
});
