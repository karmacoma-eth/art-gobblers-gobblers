// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";

interface IArtGobblers {
    /// @notice Maps gobbler ids to NFT contracts and their ids to the # of those NFT ids gobbled by the gobbler.
    function getCopiesOfArtGobbledByGobbler(
        uint256,
        address,
        uint256
    ) external returns (uint256);
}

contract ArtGobblersGobblers is
    ERC721("Art Gobblers Gobblers", "GOBBLERGOBBLER")
{
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Art Gobblers contract.
    address public immutable artGobblers;

    /// @notice The address of the Pages contract.
    address public immutable pages;

    /*//////////////////////////////////////////////////////////////
                            MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice maps gobblerGobblerIds to gobblerIds to a bool representing if they have been gobbled
    mapping(uint256 => mapping(uint256 => bool)) public gobbled;

    /// @notice the previous owner of a gobblerGobblerId, saved when it is gobbled by an Art Gobbler
    mapping(uint256 => address) public prevOwnerOf;

    mapping(uint256 => uint256) public pageIdOf;

    uint256 public totalSupply;

    /*//////////////////////////////////////////////////////////////
                             EVENTS/ERRORS
    //////////////////////////////////////////////////////////////*/

    event GobblerGobbled(
        address operator,
        uint256 gobblerGobblerId,
        uint256 gobblerId
    );

    event GobbledItsWayOut(
        address operator,
        uint256 gobblerGobblerId,
        uint256 gobblerId
    );

    error OwnerMismatch(address owner);
    error MustOwnGobblers();
    error NotGobbled();
    error WrongGobbler();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _artGobblers, address _pages) {
        artGobblers = _artGobblers;
        pages = _pages;
    }

    /*//////////////////////////////////////////////////////////////
                             MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    // TODO: mintForGoo? Using a VRGDA? :)

    /// @notice for now, open mint!
    function mint() public returns (uint256 id) {
        if (ERC721(artGobblers).balanceOf(msg.sender) == 0) {
            revert MustOwnGobblers();
        }

        unchecked {
            id = ++totalSupply;
        }

        _mint(msg.sender, totalSupply);
    }

    /*//////////////////////////////////////////////////////////////
                         GOBBLER GOBBLING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// Art Gobblers Gobblers can only gobble Art Gobblers
    function gobble(uint256 gobblerGobblerId, uint256 gobblerId) external {
        onlyGobblerGobblerOwner(gobblerGobblerId);

        emit GobblerGobbled(msg.sender, gobblerGobblerId, gobblerId);

        gobbled[gobblerGobblerId][gobblerId] = true;

        // reverts if msg.sender does not own gobblerId
        ERC721(artGobblers).transferFrom(msg.sender, address(this), gobblerId);
    }

    /// Art Gobblers Gobblers can also be gobbled by Art Gobblers
    /// When this happens, it is possible for a Gobbler Gobbler to gobble its way out of the Art Gobbler that gobbled it
    /// Anybody can call this, and the Gobbler Gobbler will return to its previous owner
    function gobbleOut(uint256 gobblerGobblerId, uint256 gobblerId) external {
        if (ownerOf[gobblerGobblerId] != artGobblers) {
            revert NotGobbled();
        }

        if (
            IArtGobblers(artGobblers).getCopiesOfArtGobbledByGobbler(
                gobblerId,
                address(this),
                gobblerGobblerId
            ) == 0
        ) {
            revert WrongGobbler();
        }

        emit GobbledItsWayOut(msg.sender, gobblerGobblerId, gobblerId);

        _transfer(artGobblers, prevOwnerOf[gobblerGobblerId], gobblerGobblerId);
    }

    function onlyGobblerGobblerOwner(uint256 gobblerGobblerId) internal view {
        address gobblerGobblerOwner = ownerOf[gobblerGobblerId];
        if (msg.sender != gobblerGobblerOwner) {
            revert OwnerMismatch(gobblerGobblerOwner);
        }
    }

    /*//////////////////////////////////////////////////////////////
                               URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice the owner of a Gobbler Gobbler can set any pageId as the corresponding
    /// token art for that Gobbler Gobbler
    function setPage(uint256 gobblerGobblerId, uint256 pageId) external {
        onlyGobblerGobblerOwner(gobblerGobblerId);

        // TODO: should we check if msg.sender also owns pageId?

        pageIdOf[gobblerGobblerId] = pageId;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        // TODO: return a default URI if the pageId has not been set

        return ERC721(pages).tokenURI(pageIdOf[id]);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev modified from solmate/tokens/ERC721.sol
    /// internal function to allow crawling back out from a gobbler's belly
    function _transfer(
        address from,
        address to,
        uint256 id
    ) internal {
        require(to != address(0), "INVALID_RECIPIENT");

        // we need checked math here because the gobbler gobbler may have already gobbled its way out
        balanceOf[from]--;

        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];
        delete prevOwnerOf[id];

        emit Transfer(from, to, id);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        if (to == artGobblers) {
            // we are getting gobbled! remember who was the pre-gobbling owner
            prevOwnerOf[id] = from;
        }

        super.transferFrom(from, to, id);
    }
}
