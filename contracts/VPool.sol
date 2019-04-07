pragma solidity >=0.4.21 <0.6.0;

contract VPool {
  uint256 public totalMintedSupply;             // The current total minted supply
  mapping(address => uint256) public balanceOf; // MINT balance of each address

  constructor() public {
    totalMintedSupply = 0;
  }

  function deposit() public payable {
    assert(msg.value > 0);

    uint256 totalLiquidity = totalMintedSupply;

    if(totalLiquidity > 0) {
      uint256 currentBalance = address(this).balance - msg.value;
      uint256 mintAmount = (totalLiquidity/currentBalance) * msg.value;
      
      totalMintedSupply = totalMintedSupply + mintAmount;
      balanceOf[msg.sender] = mintAmount;
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
}
