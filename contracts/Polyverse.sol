// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./PolyverseNFT.sol";

contract Polyverse {
    using Counters for Counters.Counter;
    Counters.Counter private _creatorIds;
    Counters.Counter private _ticketIds;

    struct Creator {
        string name;
        uint256 id;
        address nftContract;
    }

    struct Ticket {
        uint256 id;
        address owner;
        uint256 eventId;
        uint256 seatNumber;
    }

    mapping(uint256 => Creator) private _creators;
    mapping(address => uint256) private _addressToCreatorId;
    mapping(uint256 => Ticket) private _tickets;

    event CreatorAdded(uint256 indexed id, string name, address nftContract);
    event TicketCreated(uint256 indexed id, uint256 indexed eventId, address owner, uint256 seatNumber);
    event TicketPurchased(uint256 indexed id, address buyer);
    event SubscribedToCreator(uint256 indexed id, address subscriber);

    function addCreator(string memory name) public {
        _creatorIds.increment();
        uint256 creatorId = _creatorIds.current();

        // Deploy a separate NFT contract for the creator
        address nftContract = address(new PolyverseNFT(name));
        _creators[creatorId] = Creator(name, creatorId, nftContract);

        _addressToCreatorId[msg.sender] = creatorId;

        emit CreatorAdded(creatorId, name, nftContract);
    }

    function listEventTickets(uint256 eventId, uint256 numSeats) public {
        uint256 creatorId = _addressToCreatorId[msg.sender];
        require(creatorId != 0, "Invalid creator");

        PolyverseNFT nftContract = PolyverseNFT(_creators[creatorId].nftContract);
        address owner = msg.sender;

        for (uint256 i = 0; i < numSeats; i++) {
            _ticketIds.increment();
            uint256 ticketId = _ticketIds.current();
            _tickets[ticketId] = Ticket(ticketId, address(0), eventId, i);

            // Mint NFT for the ticket using the creator's NFT contract
            nftContract.mintTicket(owner, ticketId);

            emit TicketCreated(ticketId, eventId, address(0), i);
        }
    }

    function purchaseTicket(uint256 ticketId) public {
        Ticket storage ticket = _tickets[ticketId];
        require(ticket.id != 0, "Invalid ticket");
        require(ticket.owner == address(0), "Ticket already purchased");

        ticket.owner = msg.sender;
        emit TicketPurchased(ticketId, msg.sender);
    }

    function subscribeToCreator(uint256 creatorId) public {
        require(_creators[creatorId].id != 0, "Invalid creator");
        PolyverseNFT nftContract = PolyverseNFT(_creators[creatorId].nftContract);
        nftContract.mintSubscription(msg.sender);

        emit SubscribedToCreator(creatorId, msg.sender)
    }

   
}

