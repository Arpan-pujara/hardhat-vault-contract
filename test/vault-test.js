const { expect } = require('chai');
const hre = require('hardhat');

describe('Vault', function () {
  let Vault, vault, WETH, weth, owner, addr1, addr2;

  beforeEach(async function () {

    // Deploy WETH contract
    WETH = await hre.ethers.getContractFactory('WETH9');
    weth = await WETH.deploy();

    // Get Vault contract factory
    Vault = await hre.ethers.getContractFactory('Vault');

    // Get signers
    [owner, addr1, addr2] = await hre.ethers.getSigners();

    // Deploy Vault contract
    vault = await Vault.deploy(weth.target);
  });

  describe('ETH Deposits', function () {
    it('Should deposit ETH', async function () {
      await vault
        .connect(addr1)
        .depositETH({ value: hre.ethers.parseEther('1') });
      expect(await vault.getETHBalance(addr1.address)).to.equal(
        hre.ethers.parseEther('1')
      );
    });

    it('Should withdraw ETH', async function () {
      await vault
        .connect(addr1)
        .depositETH({ value: hre.ethers.parseEther('1') });
      await vault.connect(addr1).withdrawETH(hre.ethers.parseEther('1'));
      expect(await vault.getETHBalance(addr1.address)).to.equal(0);
    });
  });

  describe('Token Deposits', function () {
    it('Should deposit tokens', async function () {
      const amount = hre.ethers.parseEther('100');
      await weth.connect(addr1).deposit({ value: amount });
      await weth.connect(addr1).approve(vault.target, amount);
      await vault.connect(addr1).depositToken(weth.target, amount);
      expect(await vault.getTokenBalance(addr1.address, weth.target)).to.equal(
        amount
      );
    });

    it('Should withdraw tokens', async function () {
      const amount = hre.ethers.parseEther('100');
      await weth.connect(addr1).deposit({ value: amount });
      await weth.connect(addr1).approve(vault.target, amount);
      await vault.connect(addr1).depositToken(weth.target, amount);
      await vault.connect(addr1).withdrawToken(weth.target, amount);
      expect(await vault.getTokenBalance(addr1.address, weth.target)).to.equal(
        0
      );
    });
  });

  describe('Wrap and Unwrap ETH', function () {
    it('Should wrap ETH', async function () {
      const amount = hre.ethers.parseEther('1');
      await vault.connect(addr1).depositETH({ value: amount });
      await vault.connect(addr1).wrapETH(amount);
      expect(await vault.getETHBalance(addr1.address)).to.equal(0);
      expect(await vault.getTokenBalance(addr1.address, weth.target)).to.equal(
        amount
      );
    });

    it('Should unwrap WETH', async function () {
      const amount = hre.ethers.parseEther('1');
      const withdrawAmount = hre.ethers.parseEther('0.5');
      await vault.connect(addr1).depositETH({ value: amount });
      await vault.connect(addr1).wrapETH(amount);
      await vault.connect(addr1).unwrapWETH(withdrawAmount);
      expect(await vault.getETHBalance(addr1.address)).to.equal(amount);
      expect(await vault.getTokenBalance(addr1.address, weth.target)).to.equal(
        0
      );
    });
  });
});
