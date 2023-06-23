pragma solidity ^0.8.0;

contract Escrow {
    struct EscrowTransaction {
        address buyer;
        address seller;
        address arbitrator;
        uint256 amount;
        bool buyerApproved;
        bool sellerApproved;
        bool fundsReleased;
    }

    uint256 public escrowCount;
    mapping(uint256 => EscrowTransaction) public escrows;

    event EscrowCreated(uint256 escrowId, address buyer, address seller, address arbitrator, uint256 amount);
    event FundsDeposited(uint256 escrowId, address depositor, uint256 amount);
    event ApprovedByBuyer(uint256 escrowId);
    event ApprovedBySeller(uint256 escrowId);
    event FundsReleased(uint256 escrowId, address recipient, uint256 amount);

    function createEscrow(address _seller, address _arbitrator) public payable returns (uint256) {
        require(_seller != address(0), "Invalid seller address.");
        require(_arbitrator != address(0), "Invalid arbitrator address.");
        require(msg.value > 0, "Amount must be greater than zero.");

        uint256 escrowId = escrowCount++;
        EscrowTransaction storage escrow = escrows[escrowId];
        escrow.buyer = msg.sender;
        escrow.seller = _seller;
        escrow.arbitrator = _arbitrator;
        escrow.amount = msg.value;
        escrow.buyerApproved = false;
        escrow.sellerApproved = false;
        escrow.fundsReleased = false;

        emit EscrowCreated(escrowId, msg.sender, _seller, _arbitrator, msg.value);
        return escrowId;
    }

    function depositFunds(uint256 _escrowId) public payable {
        EscrowTransaction storage escrow = escrows[_escrowId];
        require(escrow.buyer != address(0), "Escrow does not exist.");
        require(!escrow.fundsReleased, "Funds have already been released.");
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "You are not a party to this escrow.");
        require(msg.value > 0, "Amount must be greater than zero.");

        escrow.amount += msg.value;

        emit FundsDeposited(_escrowId, msg.sender, msg.value);
    }

    function approveByBuyer(uint256 _escrowId) public {
        EscrowTransaction storage escrow = escrows[_escrowId];
        require(escrow.buyer == msg.sender, "You are not the buyer.");
        require(!escrow.fundsReleased, "Funds have already been released.");

        escrow.buyerApproved = true;

        emit ApprovedByBuyer(_escrowId);
        releaseFunds(_escrowId);
    }

    function approveBySeller(uint256 _escrowId) public {
        EscrowTransaction storage escrow = escrows[_escrowId];
        require(escrow.seller == msg.sender, "You are not the seller.");
        require(!escrow.fundsReleased, "Funds have already been released.");

        escrow.sellerApproved = true;

        emit ApprovedBySeller(_escrowId);
        releaseFunds(_escrowId);
    }

    function releaseFunds(uint256 _escrowId) internal {
        EscrowTransaction storage escrow = escrows[_escrowId];
        require(escrow.buyerApproved && escrow.sellerApproved, "Both parties have not approved yet.");

        escrow.fundsReleased = true;
        payable(escrow.seller).transfer(escrow.amount);

        emit FundsReleased(_escrowId, escrow.seller, escrow.amount);
    }
}
