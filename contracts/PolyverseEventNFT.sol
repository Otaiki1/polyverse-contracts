// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PolyverseEventNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory creatorName) ERC721(creatorName, "PVENFT") {}

    function mintTicket(address owner) external returns (uint256) {
        _tokenIds.increment();
        uint256 newTicketId = _tokenIds.current();
        _mint(owner, newTicketId);
        return newTicketId;
    }
}
