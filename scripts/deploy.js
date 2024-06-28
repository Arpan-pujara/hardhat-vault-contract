const { ethers } = require('hardhat');

async function main() {
  const WETH = await ethers.getContractFactory('WETH9');
  const weth = await WETH.deploy();

  const Vault = await ethers.getContractFactory('Vault');
  const vault = await Vault.deploy(weth.target);

  console.log(`WETH deployed to: ${weth.target}`);
  console.log(`Vault deployed to: ${vault.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
