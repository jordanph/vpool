pragma solidity >=0.4.21 <0.6.0;

contract ERC20Token {
  function balanceOf(address _owner) public view returns(uint256 balance);
  function approve(address _spender, uint256 _value) public returns (bool success);
}

contract Convertion {
  function getTokenToEthInputPrice(uint256 tokens_sold) public view returns(uint256 amount_vet);
  function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint deadline) public returns (uint256 vet_bought);
}

contract NodeContract {
  enum strengthLevel {
    None,

    // Normal Token
    Strength,
    Thunder,
    Mjolnir,

    // X Token
    VeThorX,
    StrengthX,
    ThunderX,
    MjolnirX
  }

  function applyUpgrade(strengthLevel _toLvl) public;
}

contract VPool {
  uint256 public totalMintedSupply;             // The current total minted supply
  mapping(address => uint256) public balanceOf; // MINT balance of each address
  ERC20Token public vthor;                      // vTHOR contract
  Convertion public conversion;                 // Conversion contract
  NodeContract public node;                     // Node contract

  event BalanceUpdate(
    bool deposit,
    address indexed sender,
    uint256 depositedAmount,
    uint256 userBalance,
    uint256 totalMintedSupply,
    uint256 contractBalance
  );

  event Conversion(
    uint256 thorConverted,
    uint256 vetReceived,
    uint256 contractBalance
  );

  constructor(address vthorAddress, address conversionAddress, address nodeAddress) public {
    totalMintedSupply = 0;
    vthor = ERC20Token(vthorAddress);
    conversion = Convertion(conversionAddress);
    node = NodeContract(nodeAddress);
  }

  function deposit() public payable {
    assert(msg.value > 0);
    require(msg.value <= 100 ether, "During the Alpha phase, deposits are limited to 100VET. This will be increased once auditing has been completed.");

    uint256 totalLiquidity = totalMintedSupply;

    if(totalLiquidity > 0) {
      uint256 currentBalance = address(this).balance - msg.value;
      uint256 mintAmount = msg.value * totalLiquidity/currentBalance;
      
      totalMintedSupply = totalMintedSupply + mintAmount;
      balanceOf[msg.sender] += mintAmount;
    } else {
      uint256 initialMinted = address(this).balance;
      totalMintedSupply = initialMinted;
      balanceOf[msg.sender] = initialMinted;
    }

    emit BalanceUpdate(
      true,
      msg.sender,
      msg.value,
      balanceOf[msg.sender],
      totalMintedSupply,
      address(this).balance
    );
  }

  function withdraw(uint256 amount) public {
    require(amount > 0, "You must withdraw more than 0 VET.");

    uint256 totalLiquidity = totalMintedSupply;
    assert(totalLiquidity > 0);

    uint256 senderCurrentBalance = balanceOf[msg.sender];

    require(senderCurrentBalance > 0, "You must have some VET deposited.");

    uint256 senderVETBalance = (address(this).balance * senderCurrentBalance/totalLiquidity);

    require(senderVETBalance >= (amount - 1), "You do not the required balance");

    // rounding errors: user is withdrawing entire balance
    if (amount - senderVETBalance <= 1) {
      balanceOf[msg.sender] = 0;

      totalMintedSupply = totalMintedSupply - senderCurrentBalance;
    } else {

      assert(senderVETBalance > amount);

      uint256 senderNewVETBalance = senderVETBalance - amount;

      uint256 senderNewBalance = (senderCurrentBalance * senderNewVETBalance/senderVETBalance);

      balanceOf[msg.sender] = senderNewBalance;
      totalMintedSupply = totalMintedSupply - (senderCurrentBalance - senderNewBalance);
    }

    msg.sender.transfer(amount);

    emit BalanceUpdate(
      false,
      msg.sender,
      amount,
      balanceOf[msg.sender],
      totalMintedSupply,
      address(this).balance
    );
  }

  function convertEnergy() public returns (uint256) {
    uint256 vthorBalance = vthor.balanceOf(address(this));

    vthor.approve(address(conversion), vthorBalance);

    uint256 amountVET = conversion.getTokenToEthInputPrice(vthorBalance);

    uint256 deadline = now + 1 minutes;
    uint slippageAmount = 975;

    uint256 amountReceived = conversion.tokenToEthSwapInput(vthorBalance, (amountVET * slippageAmount)/1000, deadline);

    emit Conversion(
      vthorBalance,
      amountReceived,
      address(this).balance
    );

    amountReceived;
  }

  function upgradeNodeStatus(NodeContract.strengthLevel toLvl) public {
    node.applyUpgrade(toLvl);
  }

  function() external payable { } // accept transfers
}
