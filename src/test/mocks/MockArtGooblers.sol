// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";

contract MockArtGooblers is ERC721 {
    /// @notice Maps gobbler ids to NFT contracts and their ids to the # of those NFT ids gobbled by the gobbler.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public getCopiesOfArtGobbledByGobbler;

    event ArtGobbled(
        address indexed user,
        uint256 indexed gobblerId,
        address indexed nft,
        uint256 id
    );

    error Cannibalism();
    error OwnerMismatch(address owner);

    constructor() ERC721("Mock Art Gooblers", "MOCKGOOBLER") {}

    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "https://artgobblers.com";
    }

    /*//////////////////////////////////////////////////////////////
                            GOBBLE ART LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Feed a gobbler a work of art.
    /// @param gobblerId The gobbler to feed the work of art.
    /// @param nft The ERC721 or ERC1155 contract of the work of art.
    /// @param id The id of the work of art.
    /// @param isERC1155 Whether the work of art is an ERC1155 token.
    function gobble(
        uint256 gobblerId,
        address nft,
        uint256 id,
        bool isERC1155
    ) external {
        // Get the owner of the gobbler to feed.
        address owner = ownerOf(gobblerId);

        // The caller must own the gobbler they're feeding.
        if (owner != msg.sender) revert OwnerMismatch(owner);

        // Gobblers have taken a vow not to eat other gobblers.
        if (nft == address(this)) revert Cannibalism();

        unchecked {
            // Increment the # of copies gobbled by the gobbler. Unchecked is
            // safe, as an NFT can't have more than type(uint256).max copies.
            ++getCopiesOfArtGobbledByGobbler[gobblerId][nft][id];
        }

        emit ArtGobbled(msg.sender, gobblerId, nft, id);

        isERC1155
            ? ERC1155(nft).safeTransferFrom(
                msg.sender,
                address(this),
                id,
                1,
                ""
            )
            : ERC721(nft).transferFrom(msg.sender, address(this), id);
    }
}
