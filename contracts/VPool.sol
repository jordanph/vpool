pragma solidity >=0.4.21 <0.6.0;

contract ERC20Token {
  function balanceOf(address _owner) public view returns(uint256 balance);
  function approve(address _spender, uint256 _value) public returns (bool success);
}

contract Convertion {
  function getTokenToEthInputPrice(uint256 tokens_sold) public view returns(uint256 amount_vet);
  function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint deadline) public returns (uint256 vet_bought);
}

contract VPool {
  uint256 public totalMintedSupply;             // The current total minted supply
  mapping(address => uint256) public balanceOf; // MINT balance of each address
  ERC20Token public vthor;                      // vTHOR contract
  Convertion public conversion;                 // Conversion contract

  constructor(address vthorAddress, address conversionAddress) public {
    totalMintedSupply = 0;
    vthor = ERC20Token(vthorAddress);
    conversion = Convertion(conversionAddress);
  }

  function deposit() public payable {
    assert(msg.value > 0);

    uint256 totalLiquidity = totalMintedSupply;

    if(totalLiquidity > 0) {
      uint256 currentBalance = address(this).balance - msg.value;
      uint256 mintAmount = (totalLiquidity * msg.value) / currentBalance;
      
      totalMintedSupply = totalMintedSupply + mintAmount;
      balanceOf[msg.sender] += mintAmount;
    } else {
      uint256 initialMinted = address(this).balance;
      totalMintedSupply = initialMinted;
      balanceOf[msg.sender] = initialMinted;
    }
  }

  function withdraw(uint256 amount) public {
    assert(amount > 0);

    uint256 totalLiquidity = totalMintedSupply;
    assert(totalLiquidity > 0);

    uint256 senderCurrentBalance = balanceOf[msg.sender];

    assert(senderCurrentBalance > 0);

    uint256 senderVETBalance = (address(this).balance * senderCurrentBalance/totalLiquidity);

    assert(senderVETBalance >= amount);

    uint256 senderNewVETBalance = senderVETBalance - amount;

    uint256 senderNewBalance = (senderCurrentBalance * senderNewVETBalance/senderVETBalance);

    balanceOf[msg.sender] = senderNewBalance;
    totalMintedSupply = totalMintedSupply - (senderCurrentBalance - senderNewBalance);

    msg.sender.transfer(amount);
  }

  function convertEnergy() public returns (uint256) {
    uint256 vthorBalance = vthor.balanceOf(address(this));

    vthor.approve(address(conversion), vthorBalance);

    uint256 amountVET = conversion.getTokenToEthInputPrice(vthorBalance);

    uint256 deadline = now + 1 minutes;
    uint slippageAmount = 975;

    uint256 amountReceived = conversion.tokenToEthSwapInput(vthorBalance, (amountVET * slippageAmount)/1000, deadline);

    amountReceived;
  }

  function() external payable { } // accept transfers
}
