// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {MockERC721} from "solmate/test/utils/mocks/MockERC721.sol";
import {MockArtGooblers} from "./mocks/MockArtGooblers.sol";
import {ArtGobblersGobblers} from "../ArtGobblersGobblers.sol";

contract ArtGobblersGobblersTest is Test {
    ERC721 internal pages;
    MockArtGooblers internal gobblers;
    ArtGobblersGobblers internal gobblersGobblers;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal charlie = makeAddr("charlie");

    uint256 internal ALICES_GOBBLER_ID = 41;
    uint256 internal BOBS_GOBBLER_ID = 42;
    // charlie has no Gobbler!

    uint256 internal ALICES_GOBBLER_GOBBLER_ID;
    uint256 internal BOBS_GOBBLER_GOBBLER_ID;
    // charlie has no Gobbler Gobbler!

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

    function mintAndApprove(address owner) internal returns (uint256 id) {
        vm.startPrank(owner);
        id = gobblersGobblers.mint();
        gobblers.setApprovalForAll(address(gobblersGobblers), true);
        vm.stopPrank();
    }

    function setUp() public {
        pages = new MockERC721("Pages", "PAGES");
        gobblers = new MockArtGooblers();
        gobblersGobblers = new ArtGobblersGobblers(
            address(gobblers),
            address(pages)
        );

        gobblers.mint(alice, ALICES_GOBBLER_ID);
        gobblers.mint(bob, BOBS_GOBBLER_ID);

        ALICES_GOBBLER_GOBBLER_ID = mintAndApprove(alice);
        BOBS_GOBBLER_GOBBLER_ID = mintAndApprove(bob);
    }

    function testCanGobbleOwnGobbler() public {
        vm.startPrank(bob);
        vm.expectEmit(true, true, true, true);
        emit GobblerGobbled(bob, BOBS_GOBBLER_GOBBLER_ID, BOBS_GOBBLER_ID);
        gobblersGobblers.gobble(BOBS_GOBBLER_GOBBLER_ID, BOBS_GOBBLER_ID);
        vm.stopPrank();

        assertEq(gobblers.ownerOf(BOBS_GOBBLER_ID), address(gobblersGobblers));
        assertEq(
            gobblersGobblers.gobbled(BOBS_GOBBLER_GOBBLER_ID, BOBS_GOBBLER_ID),
            true
        );
    }

    function testBobCanNotGobbleAlicesGobbler() public {
        vm.startPrank(bob);
        vm.expectRevert("WRONG_FROM");
        gobblersGobblers.gobble(BOBS_GOBBLER_GOBBLER_ID, ALICES_GOBBLER_ID);
        vm.stopPrank();
    }

    function testMustOwnGobblingGobblerGobbler() public {
        vm.startPrank(charlie);
        vm.expectRevert(abi.encodeWithSelector(OwnerMismatch.selector, bob));
        gobblersGobblers.gobble(BOBS_GOBBLER_GOBBLER_ID, BOBS_GOBBLER_ID);
        vm.stopPrank();
    }

    function testCanNotGobbleOutUngobbledGobblerGobbler() public {
        vm.startPrank(bob);
        vm.expectRevert(NotGobbled.selector);
        gobblersGobblers.gobbleOut(BOBS_GOBBLER_GOBBLER_ID, BOBS_GOBBLER_ID);
        vm.stopPrank();
    }

    function testCanNotGobbleOutFromDifferentGobbler() public {
        // bob gobbler gobbler gets gobbled
        vm.startPrank(bob);
        gobblersGobblers.setApprovalForAll(address(gobblers), true);
        gobblers.gobble({
            gobblerId: BOBS_GOBBLER_ID,
            nft: address(gobblersGobblers),
            id: BOBS_GOBBLER_GOBBLER_ID,
            isERC1155: false
        });

        // but can not call gobble out with alice's gobbler id
        vm.expectRevert(WrongGobbler.selector);
        gobblersGobblers.gobbleOut(BOBS_GOBBLER_GOBBLER_ID, ALICES_GOBBLER_ID);
        vm.stopPrank();
    }

    function testCanGobbleOut() public {
        // bob gobbler gobbler gets gobbled
        vm.startPrank(bob);
        gobblersGobblers.setApprovalForAll(address(gobblers), true);
        gobblers.gobble({
            gobblerId: BOBS_GOBBLER_ID,
            nft: address(gobblersGobblers),
            id: BOBS_GOBBLER_GOBBLER_ID,
            isERC1155: false
        });
        vm.stopPrank();

        // charlie can cause it to gobble its way out
        vm.startPrank(charlie);
        vm.expectEmit(true, true, true, true);
        emit GobbledItsWayOut(
            charlie,
            BOBS_GOBBLER_GOBBLER_ID,
            BOBS_GOBBLER_ID
        );
        gobblersGobblers.gobbleOut(BOBS_GOBBLER_GOBBLER_ID, BOBS_GOBBLER_ID);
        vm.stopPrank();

        // bob's Gobbler Gobbler is back in his wallet
        assertEq(gobblersGobblers.ownerOf(BOBS_GOBBLER_GOBBLER_ID), bob);
    }
}
