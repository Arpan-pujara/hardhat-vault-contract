const { expect } = require('chai');
const hre = require('hardhat');

describe('Vault', function () {
  let vault, weth, wethAddress, vaultAddress;
  let owner, addr1, addr2;

  before(async function () {
    [owner, addr1, addr2, _] = await ethers.getSigners();

    weth = await ethers.deployContract('WETH9');
    await weth.waitForDeployment();
    wethAddress = await weth.getAddress();
    console.log('WETH deployed to:', wethAddress);

    vault = await ethers.deployContract('Vault', [wethAddress]);
    await vault.waitForDeployment();
    vaultAddress = await vault.getAddress();
    console.log('Vault deployed to:', vaultAddress);
  });

  describe('ETH deposit and withdrawal', function () {
    it('Should deposit ETH', async function () {
      await vault
        .connect(addr1)
        .depositETH({ value: hre.ethers.parseEther('1') });
      expect(await vault.getETHBalance(addr1.address)).to.equal(
        hre.ethers.parseEther('1')
      );
    });

    it('Should withdraw ETH', async function () {
      await vault.connect(addr1).withdrawETH(hre.ethers.parseEther('1'));
      expect(await vault.getETHBalance(addr1.address)).to.equal(0);
    });

    it('Should fail to withdraw more ETH than deposited', async function () {
      const expectedError = 'Vault__InsufficientETHBalance';

      const expectedParams = [0, hre.ethers.parseEther('1')];

      await expect(vault.connect(addr1).withdrawETH(hre.ethers.parseEther('1')))
        .to.be.revertedWithCustomError(vault, expectedError)
        .withArgs(...expectedParams);
    });
  });

  describe('ERC20 deposit and withdrawal', function () {
    it('Should deposit ERC20 token', async function () {
      await weth.connect(addr1).deposit({ value: hre.ethers.parseEther('1') });
      await weth
        .connect(addr1)
        .approve(vaultAddress, hre.ethers.parseEther('1'));
      await vault
        .connect(addr1)
        .depositToken(wethAddress, hre.ethers.parseEther('1'));
      expect(await vault.getTokenBalance(addr1.address, wethAddress)).to.equal(
        hre.ethers.parseEther('1')
      );
    });

    it('Should withdraw ERC20 token', async function () {
      await vault
        .connect(addr1)
        .withdrawToken(wethAddress, hre.ethers.parseEther('1'));
      expect(await vault.getTokenBalance(addr1.address, wethAddress)).to.equal(
        0
      );
    });

    it('Should fail to withdraw more ERC20 tokens than deposited', async function () {
      await expect(
        vault
          .connect(addr1)
          .withdrawToken(wethAddress, hre.ethers.parseEther('1'))
      ).to.be.revertedWithCustomError(vault, 'Vault__InsufficientTokenBalance');
    });
  });

  describe('Wrap and unwrap ETH/WETH', function () {
    it('Should wrap ETH into WETH', async function () {
      await vault
        .connect(addr1)
        .depositETH({ value: hre.ethers.parseEther('1') });
      await vault.connect(addr1).wrapETH(hre.ethers.parseEther('1'));
      expect(await vault.getETHBalance(addr1.address)).to.equal(0);
      expect(await vault.getTokenBalance(addr1.address, wethAddress)).to.equal(
        hre.ethers.parseEther('1')
      );
    });

    it('Should unwrap WETH into ETH', async function () {
      await vault.connect(addr1).unwrapWETH(hre.ethers.parseEther('1'));
      expect(await vault.getETHBalance(addr1.address)).to.equal(
        hre.ethers.parseEther('1')
      );
      expect(await vault.getTokenBalance(addr1.address, wethAddress)).to.equal(
        0
      );
    });
  });
});
