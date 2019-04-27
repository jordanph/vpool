import { SafeMath } from "./SafeMath.sol";

pragma solidity >=0.4.21 <0.6.0;

contract ERC20Token {
  function balanceOf(address _owner) public view returns(uint256 balance);
  function approve(address _spender, uint256 _value) public returns (bool success);
}

contract Convertion {
  function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint deadline) public returns (uint256 vet_bought);
}

contract MPPContract {
  function addUser(address _self, address _user) public;
  function setCreditPlan(address _self, uint256 credit, uint256 recoveryRate) public;
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
  address public owner;                         // Account authorised to run conversion
  uint256 public lockOutTime;                   // Time locked out until another conversion can occur

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

  constructor(address vthorAddress, address conversionAddress, address nodeAddress, address mppAddress) public {
    totalMintedSupply = 0;
    vthor = ERC20Token(vthorAddress);
    conversion = Convertion(conversionAddress);
    node = NodeContract(nodeAddress);
    lockOutTime = now;
    owner = msg.sender;

    MPPContract mpp = MPPContract(mppAddress);

    mpp.addUser(address(this), owner);
    mpp.setCreditPlan(address(this), 500 ether, 500 ether);
  }

  function deposit() public payable {
    assert(msg.value > 0);
    require(msg.sender != owner, "Please don't waste people's hard earnt VTHO Mr.Owner >:(");
    require(msg.value <= 100 ether, "During the Alpha phase, deposits are limited to 100VET. This will be increased once auditing has been completed.");

    uint256 totalLiquidity = totalMintedSupply;

    if(totalLiquidity > 0) {
      uint256 currentBalance = address(this).balance - msg.value;
      uint256 mintAmount = SafeMath.mul(msg.value, totalLiquidity)/currentBalance;
      
      totalMintedSupply = SafeMath.add(totalMintedSupply, mintAmount);
      balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], mintAmount);
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
    require(msg.sender != owner, "Please don't waste people's hard earnt VTHO Mr.Owner >:(");
    require(amount > 0, "You must withdraw more than 0 VET.");

    uint256 totalLiquidity = totalMintedSupply;
    assert(totalLiquidity > 0);

    uint256 senderCurrentBalance = balanceOf[msg.sender];

    require(senderCurrentBalance > 0, "You must have some VET deposited.");

    uint256 senderVETBalance = SafeMath.mul(address(this).balance, senderCurrentBalance)/totalLiquidity;

    require(senderVETBalance >= (amount - 1), "You do not the required balance");

    // rounding errors: user is withdrawing entire balance
    if (amount - senderVETBalance <= 1) {
      balanceOf[msg.sender] = 0;

      totalMintedSupply = SafeMath.sub(totalMintedSupply, senderCurrentBalance);
    } else {

      assert(senderVETBalance > amount);

      uint256 senderNewVETBalance = senderVETBalance - amount;

      uint256 senderNewBalance = SafeMath.mul(senderCurrentBalance, senderNewVETBalance)/senderVETBalance;

      balanceOf[msg.sender] = senderNewBalance;
      totalMintedSupply = SafeMath.sub(totalMintedSupply, senderCurrentBalance - senderNewBalance);
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

  function convertEnergy(uint256 amountVET) public returns (uint256) {
    require(msg.sender == owner, "Only the owner of the contract can initiate a conversion.");

    uint256 vthorBalance = vthor.balanceOf(address(this));

    uint256 linearLockOutTime = 1 weeks * vthorBalance / 20000 ether;
    
    require(lockOutTime - linearLockOutTime < now, "Can only convert according to linear lockout time.");

    vthor.approve(address(conversion), vthorBalance);

    uint256 deadline = now + 1 minutes;

    uint256 amountReceived = conversion.tokenToEthSwapInput(vthorBalance, amountVET, deadline);

    lockOutTime = now + 1 weeks;

    emit Conversion(
      vthorBalance,
      amountReceived,
      address(this).balance
    );

    return amountReceived;
  }

  function upgradeNodeStatus(NodeContract.strengthLevel toLvl) public {
    node.applyUpgrade(toLvl);
  }

  function() external payable { } // accept transfers
}
