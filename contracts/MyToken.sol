// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Administrable {
	address private _admin;

    event AdminshipTransferred(address indexed currentAdmin, address indexed newAdmin);

	constructor() {
		_admin = msg.sender;
        emit AdminshipTransferred(address(0), _admin);
	}

    function admin() public view returns (address) {
        return _admin;
    }

	modifier onlyAdmin() {
		require(msg.sender == _admin, "Only Admin can perform this action.");
		_;
	}

	function transferAdminship(address newAdmin) public onlyAdmin {
        emit AdminshipTransferred(_admin, newAdmin);
        _admin = newAdmin;
	}
}

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract MyToken {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits) {
        _balances[address(this)] = initialSupply;
        _totalSupply = initialSupply;
        _decimals = decimalUnits;
        _symbol = tokenSymbol;
        _name = tokenName;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setTotalSupply(uint256 totalAmount) internal {
        _totalSupply = totalAmount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setBalance(address account, uint256 balance) internal {
        _balances[account] = balance;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAllowance(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
    }

    function transfer(address beneficiary, uint256 amount) public virtual returns (bool) {
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(_balances[msg.sender] >= amount, "Sender does not have enough balance.");
        require(_balances[beneficiary] + amount > _balances[beneficiary], "Addition overflow");

        _balances[msg.sender] -= amount;
        _balances[beneficiary] += amount;
        emit Transfer(msg.sender, beneficiary, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        require(spender != address(0), "Spender address cannot be zero.");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address beneficiary, uint256 amount)  public virtual  returns (bool) {
        require(sender != address(0), "Sender address cannot be zero.");
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(amount <= _allowances[sender][msg.sender], "Allowance is not enough");
        require(_balances[sender] >= amount, "Sender does not have enough balance.");
        require(_balances[beneficiary] + amount > _balances[beneficiary], "Addition overflow");

        _balances[sender] -= amount;
        _allowances[sender][msg.sender] -= amount;
        _balances[beneficiary] += amount;
        emit Transfer(sender, beneficiary, amount);
        return true;
    }
}   

pragma solidity ^0.8.0;

contract MyTokenAdvanced is MyToken, Administrable {

    // Mapping to keep track of frozen accounts
    mapping (address => bool) private _frozenAccounts;

    // Mapping to keep track of pending withdrawals
    mapping (address => uint) private _pendingWithdrawals;

    // Mapping to keep track of staked tokens
    mapping (address => uint) public staked;

    // Mapping to keep track of staked tokens at the time of staking
    mapping (address => uint) private stakedFromTS;

    // Mapping to keep track of staking time
    mapping (address => uint) private stakingTime;

    // Price of token when selling in wei (ether per token)
    uint256 private _sellPrice = 1 ether;

    // Price of token when buying in wei (ether per token)
    uint256 private _buyPrice = 1 ether;

    // Transaction fees charged on every buy/sell operation
    uint256 constant FEES = 5; // 5% fees

    // Event emitted when an account is frozen
    event FrozenFund(address indexed target, bool frozen);

    // Event emitted when tokens are staked
    event Staked(address indexed staker, uint256 amount);

    // Event emitted when tokens are withdrawn from staking
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @dev Constructor function that initializes the MyTokenAdvanced contract
     * with initial supply, name, symbol, decimal units and the address of newAdmin.
     * Also sets the initial balance of the contract address and total supply of tokens.
     */
    constructor(
        uint256 initialSupply, 
        string memory tokenName, 
        string memory tokenSymbol, 
        uint8 decimalUnits, 
        address newAdmin
    ) MyToken(0, tokenName, tokenSymbol, decimalUnits) {
        if(newAdmin != address(0) && newAdmin != msg.sender) {
            transferAdminship(newAdmin);
        }

        setBalance(address(this), initialSupply);
        setTotalSupply(initialSupply);
    }

    /**
     * @dev Returns the current sell price of token in wei.
     */
    function sellPrice() public view returns (uint256) {
        return _sellPrice;
    }

    /**
     * @dev Returns the current buy price of token in wei.
     */
    function buyPrice() public view returns (uint256) {
        return _buyPrice;
    }

    /**
     * @dev Sets the sell and buy price of tokens in wei.
     * Can only be called by the admin.
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyAdmin {
        require(newSellPrice > 0, "Sell price cannot be zero.");
        require(newBuyPrice > 0, "Buy price cannot be zero.");

        _sellPrice = newSellPrice;
        _buyPrice = newBuyPrice;
    }

    /**
     * @dev Mints new tokens to a specified account.
     * Can only be called by the admin.
     */
    function mintToken(address target, uint256 mintedAmount) public onlyAdmin {
        require(balanceOf(target) + mintedAmount > balanceOf(target), "Addition overflow");
        require(totalSupply() + mintedAmount > totalSupply(), "Addition overflow");

        setBalance(target, balanceOf(target) + mintedAmount);
        setTotalSupply(totalSupply() + mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public onlyAdmin {
        _frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze);
    }

    function transfer(address beneficiary, uint256 amount) public override returns (bool) {
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(balanceOf(msg.sender) >= amount, "Sender does not have enough balance.");
        require(balanceOf(beneficiary) + amount > balanceOf(beneficiary), "Addition overflow");
        require(!_frozenAccounts[msg.sender], "Sender's account is frozen.");

        setBalance(msg.sender, balanceOf(msg.sender) - amount);
        setBalance(beneficiary, balanceOf(beneficiary) + amount);
        emit Transfer(msg.sender, beneficiary, amount);
        return true;
    }

    function transferFrom(address sender, address beneficiary, uint256 amount)  public override returns (bool) {
        require(sender != address(0), "Sender address cannot be zero.");
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(amount <= allowance(sender, msg.sender), "Allowance is not enough");
        require(balanceOf(sender) >= amount, "Sender does not have enough balance.");
        require(balanceOf(beneficiary) + amount > balanceOf(beneficiary), "Addition overflow");
        require(!_frozenAccounts[sender], "Sender's account is frozen.");

        setBalance(sender, balanceOf(sender) - amount);
        setAllowance(sender, msg.sender, allowance(sender, msg.sender) - amount);
        setBalance(beneficiary, balanceOf(beneficiary) + amount);
        emit Transfer(sender, beneficiary, amount);
        return true;
    }

    function buy() public payable {
        address thisContractAddress = address(this);
        uint256 fees = msg.value*FEES/100;
        uint256 valueAfterFee = msg.value - fees; 
        uint256 amount = valueAfterFee/(_buyPrice/100);

        require(balanceOf(thisContractAddress) >= amount, "Contract does not have enough tokens.");
        require(balanceOf(msg.sender) + amount > balanceOf(msg.sender), "Addition overflow");
        setBalance(thisContractAddress, balanceOf(thisContractAddress) - amount);
        setBalance(msg.sender, balanceOf(msg.sender) + amount);
        payable(admin()).transfer(fees); 
        emit Transfer(thisContractAddress, msg.sender, amount);
    } 

    function sell(uint256 amount) public {
        address thisContractAddress = address(this);
        require(balanceOf(msg.sender) >= amount, "You do not have enough tokens to sell.");
        require(balanceOf(thisContractAddress) + amount > balanceOf(thisContractAddress), "Addition overflow");

        uint256 value_in_eth = amount * sellPrice()/100;
        uint256 fees = value_in_eth * (FEES/100);
        uint256 eth_to_pay = value_in_eth - fees;

        setBalance(msg.sender, balanceOf(msg.sender) - amount);
        setBalance(thisContractAddress, balanceOf(thisContractAddress) + amount);
        payable(msg.sender).transfer(eth_to_pay);
        payable(admin()).transfer(fees);

        emit Transfer(msg.sender, thisContractAddress, amount);
    }

    function withdraw() public {
        uint amount = _pendingWithdrawals[msg.sender];
        _pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }


    function withdrawFunds(uint256 amount) public onlyAdmin {
        require(address(this).balance >= amount, "Insufficient balance in contract");

        // Swap ETH for WETH via Uniswap V2
        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        uint256[] memory amounts = router.swapExactETHForTokens{value: amount}(0, path, address(this), block.timestamp);

        // Transfer WETH to msg.sender
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).transfer(msg.sender, amounts[1]);
    }

    function stake(uint256 amount, uint256 lockTime) public {
        require(amount > 0, "Amount should be greater than zero.");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance.");
        require(stakingTime[msg.sender] < lockTime, "You already have tokens staked for a longer period!");

        setBalance(msg.sender, balanceOf(msg.sender) - amount);

        staked[msg.sender] += amount;
        stakedFromTS[msg.sender] = block.timestamp;
        stakingTime[msg.sender] = lockTime;
        emit Staked(msg.sender, amount);
    }

    function claim() public {
        require(staked[msg.sender] > 0, "No tokens staked.");
        uint256 stakedTime_in_seconds = block.timestamp - stakedFromTS[msg.sender];
        uint256 timeToWait = stakingTime[msg.sender] / 12 * 31560000;
        require(stakedTime_in_seconds < timeToWait, "Too soon to unstake ! ");

        // 20% rewards if staking time > 3 months
        if (stakingTime[msg.sender] >= 3) {
            uint256 rewards = staked[msg.sender] * 2 / 10 * stakedTime_in_seconds / 31560000;
            setBalance(msg.sender, balanceOf(msg.sender) + rewards);

        } else {
            uint256 rewards = staked[msg.sender] / 10 * stakedTime_in_seconds / 31560000;
            setBalance(msg.sender, balanceOf(msg.sender) + rewards);
        }
    }

    function unstake(uint256 amount) public {
        require(staked[msg.sender] >= amount, "No tokens staked.");
        require(amount>0, "amount < 0");
        uint256 stakedTime_in_seconds = block.timestamp - stakedFromTS[msg.sender];
        uint256 timeToWait = stakingTime[msg.sender] / 12 * 31560000;
        require(stakedTime_in_seconds < timeToWait, "Too soon to unstake ! ");

        claim();
        setBalance(msg.sender, balanceOf(msg.sender) + amount);
        staked[msg.sender] -= amount;
        transfer(msg.sender, amount);
    }
}