import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TokenModule = buildModule("StradeBase", (m) => {
    const initial_supply = 200_000_000;
    const token = m.contract("StradeBaseToken", [initial_supply]);

    if (token) {
        //  Deploy vault contract with the address of StradeBaseToken
        const vault = m.contract("Vault", [token]);
        if (!vault) {
            console.error("Failed to deploy Vault");
            return;
        }

        //  Deploy staking contract with the address of StradeBaseToken and vault
        const staking = m.contract("Staking", [token, vault]);
        if (!staking) {
            console.error("Failed to deploy Staking");
            return;
        }

    } else {
        console.error("Failed to deploy StradeBaseToken");
    }
    return {token};
});

export default TokenModule
