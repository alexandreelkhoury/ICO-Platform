const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

describe("MyToken", function() {
  let myToken, owner, user1, user2;
  
  before(async function() {
    // Get some test accounts
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy MyToken contract
    const MyToken = await hre.ethers.getContractFactory("MyToken");
    myToken = await MyToken.deploy(
      newOwner = await owner.getAddress(),    
      _name = "MyToken",
      _symbol = "MTK",
      _price = ethers.utils.parseEther("0.01"),
      _decimals = 18,
      totalSupply = "1000000"
    );

    await myToken.deployed();

    // Mint some tokens to the owner for testing
    await myToken.mint({value: ethers.utils.parseEther("100"),  gasPrice: ethers.utils.parseUnits("20", "gwei")});
  });

  it("should have the correct name and symbol", async function() {
    expect(await myToken.name()).to.equal("MyToken");
    expect(await myToken.symbol()).to.equal("MTK");
  });

  it("should have the correct decimals", async function() {
    expect(await myToken.decimals()).to.equal(18);
  });

  it("should have the correct initial total supply", async function() {
    expect(await myToken.totalSupply()).to.equal(ethers.utils.parseEther("1000000"));
  });

  it("should have the correct initial circulating supply", async function() {
    expect(await myToken.circulatingSupply()).to.equal(ethers.utils.parseEther("210000"));
  });

  it("should have the correct balance for the owner after minting", async function() {
    expect(await myToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("210000"));
  });

  it("should allow the owner to transfer tokens", async function() {
    const amount = ethers.utils.parseEther("100");
    await myToken.transfer(user1.address, amount);
    expect(await myToken.balanceOf(user1.address)).to.equal(amount);
  });

  it("should not allow a blocked account to transfer tokens", async function() {
    await myToken.blockAccount(user1.address);
    await expect(myToken.transfer(user1.address, ethers.utils.parseEther("10")))
      .to.be.revertedWith("Account is blocked");
  });

  it("should allow a blocked account to be unblocked", async function() {
    await myToken.unblockAccount(user1.address);
    expect(await myToken.isBlocked(user1.address)).to.be.false;
  });

  it("should allow the owner to change the token price", async function() {
    const newPrice = ethers.utils.parseEther("0.002");
    await myToken.changePrice(newPrice);
    expect(await myToken.price()).to.equal(newPrice);
  });

  it("should allow the owner to airdrop tokens", async function() {
    const amount = ethers.utils.parseEther("1");
    await myToken.airdrop(amount, user1.address);
    expect(await myToken.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("11"));
  });
  it("should allow an admin to freeze an account", async function() {
    await myToken.freezeAccount(user1.address, true);
    expect(await myToken.frozenAccounts(user1.address)).to.equal(true);
  });

  it("should allow an admin to unfreeze an account", async function() {
    await myToken.freezeAccount(user1.address, false);
    expect(await myToken.frozenAccounts(user1.address)).to.equal(false);
  });

  it("should allow an admin to set the sell and buy prices", async function() {
    const newSellPrice = ethers.utils.parseEther("0.005");
    const newBuyPrice = ethers.utils.parseEther("0.007");
    await myToken.setPrices(newSellPrice, newBuyPrice);
    expect(await myToken.sellPrice()).to.equal(newSellPrice);
    expect(await myToken.buyPrice()).to.equal(newBuyPrice);
  });

  it("should not allow a non-admin to set the sell and buy prices", async function() {
    const newSellPrice = ethers.utils.parseEther("0.005");
    const newBuyPrice = ethers.utils.parseEther("0.007");
    await expect(myToken.connect(user1).setPrices(newSellPrice, newBuyPrice))
      .to.be.revertedWith("Only the admin can call this function.");
  });
  it("should not allow a user to stake more tokens than they have", async function() {
    await expect(myTokenAdvanced.connect(user1).stake(ethers.utils.parseEther("1000")))
    .to.be.revertedWith("Insufficient balance");
  });
    
  it("should allow a user to stake tokens", async function() {
    const amount = ethers.utils.parseEther("100");
    await myTokenAdvanced.connect(user1).stake(amount);
    expect(await myTokenAdvanced.staked(user1.address)).to.equal(amount);
  });
    
  it("should update the staked balance when transferring tokens", async function() {
    const amount = ethers.utils.parseEther("100");
    await myTokenAdvanced.connect(user1).stake(amount);
    await myTokenAdvanced.transfer(user2.address, amount, {from: user1.address});
    expect(await myTokenAdvanced.staked(user1.address)).to.equal(0);
    expect(await myTokenAdvanced.staked(user2.address)).to.equal(amount);
  });
    
  it("should allow a user to withdraw staked tokens", async function() {
    const amount = ethers.utils.parseEther("100");
    await myTokenAdvanced.connect(user1).stake(amount);
    await myTokenAdvanced.connect(user1).withdraw(amount);
    expect(await myTokenAdvanced.staked(user1.address)).to.equal(0);
    expect(await myTokenAdvanced.balanceOf(user1.address)).to.equal(amount);
  });
    
  it("should have the correct pending withdrawals after staking", async function() {
    const amount = ethers.utils.parseEther("100");
    await myTokenAdvanced.connect(user1).stake(amount);
    expect(await myTokenAdvanced.pendingWithdrawals(user1.address)).to.equal(0);
    await myTokenAdvanced.connect(user1).withdraw(amount);
    expect(await myTokenAdvanced.pendingWithdrawals(user1.address)).to.equal(amount);
  });
    
  it("should allow the admin to withdraw pending withdrawals", async function() {
    const amount = ethers.utils.parseEther("100");
    await myTokenAdvanced.connect(user1).stake(amount);
    await myTokenAdvanced.connect(user1).withdraw(amount);
    await myTokenAdvanced.connect(owner).withdrawPendingWithdrawals(user1.address);
    expect(await myTokenAdvanced.pendingWithdrawals(user1.address)).to.equal(0);
    expect(await ethers.provider.getBalance(user1.address)).to.equal(amount);
  });
});
