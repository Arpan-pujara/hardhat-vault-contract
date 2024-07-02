const { ethers } = require('hardhat');

async function main() {
  const weth = await ethers.deployContract('WETH9');
  await weth.waitForDeployment();
  const wethAddress = await weth.getAddress();
  console.log('WETH deployed to:', wethAddress);

  const vault = await ethers.deployContract('Vault', [wethAddress]);
  await vault.waitForDeployment();
  vaultAddress = await vault.getAddress();
  console.log('Vault deployed to:', vaultAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
