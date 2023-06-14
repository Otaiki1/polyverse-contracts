// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PolyverseCreatorNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory creatorName) ERC721(creatorName, "PVCNFT") {}

    function mintSubscription(address subscriber) external {
        _tokenIds.increment();
        uint256 newSubscriptionId = _tokenIds.current();
        _mint(subscriber, newSubscriptionId);
    }
}
