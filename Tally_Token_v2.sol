pragma solidity ^0.4.19;

import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract TALLY is ERC827Token, Ownable
{
    using SafeMath for uint256;
    
    string public constant name = "TALLY";
    string public constant symbol = "TLY";
    uint256 public constant decimals = 18;
    
    address public foundationAddress;
    address public developmentFundAddress;
    uint256 public constant DEVELOPMENT_FUND_LOCK_TIMESPAN = 2 years;
    
    uint256 public developmentFundUnlockTime;
    
    bool public tokenSaleEnabled;
    
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSaleTLYperETH;
    
    uint256 public preferredSaleStartTime;
    uint256 public preferredSaleEndTime;
    uint256 public preferredSaleTLYperETH;

    uint256 public mainSaleStartTime;
    uint256 public mainSaleEndTime;
    uint256 public mainSaleTLYperETH;
    
    uint256 public preSaleTokensLeftForSale = 70000000 * (uint256(10)**decimals);
    uint256 public preferredSaleTokensLeftForSale = 70000000 * (uint256(10)**decimals);
    
    uint256 public minimumAmountToParticipate = 0.5 ether;
    
    mapping(address => uint256) public addressToSpentEther;
    mapping(address => uint256) public addressToPurchasedTokens;
    
    function TALLY() public
    {
        owner = 0xd512fa9Ca3DF0a2145e77B445579D4210380A635;
        developmentFundAddress = 0x4D18700A05D92ae5e49724f13457e1959329e80e;
        foundationAddress = 0xf1A2e7a164EF56807105ba198ef8F2465B682B16;
        
        balances[developmentFundAddress] = 300000000 * (uint256(10)**decimals);
        Transfer(0x0, developmentFundAddress, balances[developmentFundAddress]);
        
        balances[this] = 1000000000 * (uint256(10)**decimals);
        Transfer(0x0, this, balances[this]);
        
        totalSupply_ = balances[this] + balances[developmentFundAddress];
        
        preSaleTLYperETH = 30000;
        preferredSaleTLYperETH = 25375;
        mainSaleTLYperETH = 20000;
        
        preSaleStartTime = 1518652800;
        preSaleEndTime = 1519516800; // 15 february 2018 - 25 february 2018
        
        preferredSaleStartTime = 1519862400;
        preferredSaleEndTime = 1521072000; // 01 march 2018 - 15 march 2018
        
        mainSaleStartTime = 1521504000;
        mainSaleEndTime = 1526774400; // 20 march 2018 - 20 may 2018
        
        tokenSaleEnabled = true;
        
        developmentFundUnlockTime = now + DEVELOPMENT_FUND_LOCK_TIMESPAN;
    }
    
    function () payable external
    {
        require(tokenSaleEnabled);
        
        require(msg.value >= minimumAmountToParticipate);
        
        uint256 tokensPurchased;
        if (now >= preSaleStartTime && now < preSaleEndTime)
        {
            tokensPurchased = msg.value.mul(preSaleTLYperETH);
            preSaleTokensLeftForSale = preSaleTokensLeftForSale.sub(tokensPurchased);
        }
        else if (now >= preferredSaleStartTime && now < preferredSaleEndTime)
        {
            tokensPurchased = msg.value.mul(preferredSaleTLYperETH);
            preferredSaleTokensLeftForSale = preferredSaleTokensLeftForSale.sub(tokensPurchased);
        }
        else if (now >= mainSaleStartTime && now < mainSaleEndTime)
        {
            tokensPurchased = msg.value.mul(mainSaleTLYperETH);
        }
        else
        {
            revert();
        }
        
        addressToSpentEther[msg.sender] = addressToSpentEther[msg.sender].add(msg.value);
        addressToPurchasedTokens[msg.sender] = addressToPurchasedTokens[msg.sender].add(tokensPurchased);
        
        this.transfer(msg.sender, tokensPurchased);
    }
    
    function refund() external
    {
        // Only allow refunds before the main sale has ended
        require(now < mainSaleEndTime);
        
        uint256 tokensRefunded = addressToPurchasedTokens[msg.sender];
        uint256 etherRefunded = addressToSpentEther[msg.sender];
        addressToPurchasedTokens[msg.sender] = 0;
        addressToSpentEther[msg.sender] = 0;
        
        // Send the tokens back to this contract
        balances[msg.sender] = balances[msg.sender].sub(tokensRefunded);
        balances[this] = balances[this].add(tokensRefunded);
        Transfer(msg.sender, this, tokensRefunded);
        
        // Add the tokens back to the pre-sale or preferred sale
        if (now < preSaleEndTime)
        {
            preSaleTokensLeftForSale = preSaleTokensLeftForSale.add(tokensRefunded);
        }
        else if (now < preferredSaleEndTime)
        {
            preferredSaleTokensLeftForSale = preferredSaleTokensLeftForSale.add(tokensRefunded);
        }
        
        // Send the ether back to the user
        msg.sender.transfer(etherRefunded);
    }
    
    // Prevent the development fund from transferring its tokens while they are locked
    function transfer(address _to, uint256 _value) public returns (bool)
    {
        if (msg.sender == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transfer(_to, _value);
    }
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool)
    {
        if (msg.sender == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transfer(_to, _value, _data);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        if (_from == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transferFrom(_from, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool)
    {
        if (_from == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transferFrom(_from, _to, _value, _data);
    }
    
    // Allow the owner to retrieve all the collected ETH
    function drain() external onlyOwner
    {
        owner.transfer(this.balance);
    }
    
    // Allow the owner to enable or disable the token sale at any time.
    function enableTokenSale() external onlyOwner
    {
        tokenSaleEnabled = true;
    }
    function disableTokenSale() external onlyOwner
    {
        tokenSaleEnabled = false;
    }
    
    function moveUnsoldTokensToFoundation() external onlyOwner
    {
        this.transfer(foundationAddress, balances[this]);
    }
    
    // Pre-sale configuration
    function setPreSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        preSaleTLYperETH = _newTLYperETH;
    }
    function setPreSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        preSaleStartTime = _newStartTime;
        preSaleEndTime = _newEndTime;
    }
    
    // Preferred sale configuration
    function setPreferredSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        preferredSaleTLYperETH = _newTLYperETH;
    }
    function setPreferredSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        preferredSaleStartTime = _newStartTime;
        preferredSaleEndTime = _newEndTime;
    }
    
    // Main sale configuration
    function setMainSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        mainSaleTLYperETH = _newTLYperETH;
    }
    function setMainSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        mainSaleStartTime = _newStartTime;
        mainSaleEndTime = _newEndTime;
    }
}
