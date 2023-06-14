// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PolyverseCreatorNFT.sol";
import "./PolyverseEventNFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error NotEnoughAmount();
error InvalidCreator();
error FullEvent();
error EventOver();

contract Polyverse {
    using Counters for Counters.Counter;
    Counters.Counter private _creatorIds;
    Counters.Counter private _ticketIds;
    Counters.Counter private _eventIds;

    struct Creator {
        bytes creatorData;
        address nftContract;
        uint subscriptionFee;
        address[] subscribers;
        uint balance;
    }

    struct Ticket {
        address owner;
        uint256 eventId;
        uint256 seatNumber;
        uint256 ticketNFTId;
    }

    struct Event {
        address eventNFT;
        uint256 maxParticipants;
        uint256 deadline;
        uint256 ticketPrice;
        bytes eventData;
        address[] participants;
    }

    mapping(uint256 => Creator) private _creators;
    mapping(address => uint256) public _addressToCreatorId;
    mapping(uint256 => Event) private _events;
    mapping(address => uint256) public _userToTicketId;
    mapping(uint256 => Ticket) private _tickets;

    event CreatorAdded(
        uint256 indexed id,
        address nftContract,
        uint subscriptionFee
    );

    event EventCreated(
        uint256 indexed eventId,
        address owner,
        uint256 maxParticipants,
        uint256 indexed ticketPrice
    );

    event TicketPurchased(
        uint256 indexed eventId,
        address buyer,
        uint256 indexed ticketNFTId
    );

    event SubscribedToCreator(uint256 indexed id, address subscriber);

    function addCreator(
        bytes memory creatorData,
        uint subscriptionFee,
        string memory creatorName
    ) public {
        _creatorIds.increment();
        uint256 creatorId = _creatorIds.current();

        address[] memory emptyAddressArray;

        // Deploy a separate NFT contract for the creator
        address nftContract = address(new PolyverseCreatorNFT(creatorName));
        _creators[creatorId] = Creator(
            creatorData,
            nftContract,
            subscriptionFee,
            emptyAddressArray,
            0
        );

        _addressToCreatorId[msg.sender] = creatorId;

        emit CreatorAdded(creatorId, nftContract, subscriptionFee);
    }

    function subscribeToCreator(uint256 creatorId) public payable {
        Creator storage creator = _creators[creatorId];
        require(creator.nftContract != address(0), "Invalid creator");
        require(msg.value >= creator.subscriptionFee, "Not enough amount");

        PolyverseCreatorNFT nftContract = PolyverseCreatorNFT(
            creator.nftContract
        );
        nftContract.mintSubscription(msg.sender);

        creator.subscribers.push(msg.sender);
        creator.balance += msg.value;

        emit SubscribedToCreator(creatorId, msg.sender);
    }

    function listEvent(
        uint256 numSeats,
        bytes memory eventData,
        uint256 ticketPrice,
        uint256 deadline,
        string memory eventName
    ) public {
        uint256 creatorId = _addressToCreatorId[msg.sender];
        require(creatorId != 0, "Invalid creator");

        address nftContract = address(new PolyverseEventNFT(eventName));
        _eventIds.increment();

        Event storage newEvent = _events[_eventIds.current()];
        newEvent.eventNFT = nftContract;
        newEvent.maxParticipants = numSeats;
        newEvent.deadline = deadline;
        newEvent.ticketPrice = ticketPrice;
        newEvent.eventData = eventData;

        emit EventCreated(
            _eventIds.current(),
            msg.sender,
            numSeats,
            ticketPrice
        );
    }

    function purchaseTicket(uint256 eventId) public payable {
        Event storage eventDetails = _events[eventId];
        require(msg.value >= eventDetails.ticketPrice, "Not enough amount");
        require(
            eventDetails.participants.length < eventDetails.maxParticipants,
            "Full event"
        );
        require(block.timestamp <= eventDetails.deadline, "Event over");

        PolyverseEventNFT nftContract = PolyverseEventNFT(
            eventDetails.eventNFT
        );

        _ticketIds.increment();
        uint256 ticketNFTId = nftContract.mintTicket(msg.sender);
        _userToTicketId[msg.sender] = _ticketIds.current();

        Ticket storage newTicket = _tickets[_ticketIds.current()];
        newTicket.owner = msg.sender;
        newTicket.eventId = eventId;
        newTicket.seatNumber = eventDetails.participants.length;
        newTicket.ticketNFTId = ticketNFTId;

        eventDetails.participants.push(msg.sender);

        emit TicketPurchased(eventId, msg.sender, ticketNFTId);
    }

    function getCreator(
        uint256 creatorId
    )
        public
        view
        returns (bytes memory, address, uint256, address[] memory, uint256)
    {
        Creator memory creator = _creators[creatorId];
        return (
            creator.creatorData,
            creator.nftContract,
            creator.subscriptionFee,
            creator.subscribers,
            creator.balance
        );
    }

    function getEvent(
        uint256 eventId
    )
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bytes memory,
            address[] memory
        )
    {
        Event memory eventDetails = _events[eventId];
        return (
            eventDetails.eventNFT,
            eventDetails.maxParticipants,
            eventDetails.deadline,
            eventDetails.ticketPrice,
            eventDetails.eventData,
            eventDetails.participants
        );
    }

    function getTicket(
        uint256 ticketId
    ) public view returns (address, uint256, uint256, uint256) {
        Ticket memory ticket = _tickets[ticketId];
        return (
            ticket.owner,
            ticket.eventId,
            ticket.seatNumber,
            ticket.ticketNFTId
        );
    }
}
