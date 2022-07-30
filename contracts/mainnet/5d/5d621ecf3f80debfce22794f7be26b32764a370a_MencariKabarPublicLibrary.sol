/**
 *Submitted for verification at FtmScan.com on 2022-07-29
*/

// SPDX-License-Identifier: MIT

/**
These contract and archive are reproduced and distributed to the 
blockchain by the PROYEK EDISI, a Yogyakarta-based young artists' 
initiative, as part of a performance artwork and performative 
archive project, entitled “Mencari Kabar”.

This project is supported by the CEMETI - INSTITUTE FOR ART AND 
SOCIETY, Yogyakarta, within the framework of the 2022 Rimpang Nusantara 
programme.


                    -*====++-           .:.              --.:   
                   *-       :*.      -++=--++          ==:*#*++ 
                  =*         :%     *-       *:      .# [email protected]@@==.#
                   =+      :-*:    *:        =#      #:[email protected]#@%+= %
            .=**++*#=  :*+=-:      .+:   .:--+:      *[email protected]+++-.*:
           *=+:       .#=.          -# .#=-:.         =+.=*++=  
         ++-*#          :+#*=+++*++*=  +.              #-*.     
       =*+= +:          .#:**          .+*+-:    .#**++= #++=-: 
     :+=*. :+           #[email protected]=             ..=%  .*           +# 
   .*+*:   *.          =% *%   #+        =% .% .+-:          ++ 
  =+*=    +:          :@= @= .*#.        %# .#.=.#=       *+ *+ 
-+-+     =-   :      :+# :# .+-*        -*+ .** +#:      ==+.*- 
=*-     =+   #*      *+* #:.+ =:       .#.=. @:=+=       * *-%+ 
       -*  :**.    .%-=-.*==  *.       -+ +=#++=+:  %.  .#.%:%= 
      :*  -+ *.   [email protected]: ==*#:  -+    -   *:  +==--+  [email protected]   .*.*.%= 
     .#  =+ :+  .#..   =.    *:   *@  :*       #. :*#   -* # *+ 
  :=*+. =+  =*  #.          :*   +=%. :#      ++  +=#   *= *.=+ 
:%*--: -*   ++ *=           ==  *: %- =+      *. == %   *- .++* 
   .:-=-    #  %-.       .-=*. *:  *- =*     :#  * :%  .#    :  
            :*+++##.    *+:.  *-   *- .*--  :#- -+ =%  -*
                .:      .=+++*:     -++===##:   *= +#  *+  
                                        ::.:+*==#  *+  +%:
                                               ::  =+    =#.
                                                    -#===+-
PROYEK EDISI's current members:

Azwar Ahmad
Eka Wahyuni
Faida Rachma
Ignatius Suluh
Maria Silalahi
Muhammad Dzulqornain
Nisa Ramadani
Pinka Oktafiatun Qumaira
Prashasti Wilujeng Putri
Ridho Afwan Rahman
Syahidin Pamungkas
Wildan Iltizam
Dini Adanurani

Performed on July 30th, 2022 in Yogyakarta
Thanks to FantomPocong and Tooftolenk

           :*@@-.         .::   
         :[email protected]%%@@%=.  [email protected]@@=: 
   ******@@%%#=*%%#**%@@*=-+%@* 
.=%%%%@@%%@@=:::[email protected]@%@%#:[email protected]#%@.  
+#%@@@+*@#**-::+***#*=:++=%%%*- 
 [email protected]@@++=:.::::::::::::+*%@*-
   ...#%#%#.:::::::::::#%%.
       .*%#-=-:-=:[email protected]@%*-
        =#@%@@+%%*++=#%=.
      **[email protected]%-*@@@@@%#:+%-+#
     :**.:[email protected]%######%@*-:+%:.
    [email protected]@@=        =%@:.:@+
    [email protected]:-#-:**##: *##*=-#[email protected]+
    [email protected]:[email protected] [email protected]:[email protected] @[email protected]+ @*[email protected]+
    [email protected]:[email protected]  ****. ****: @*[email protected]+
    [email protected]:[email protected]#=    +*    :*@[email protected]+
    -%%@@@@%:  ..   %@@@@%%+
      #*.%@@+: :- [email protected]@@[email protected]
      %#.=*@[email protected]%[email protected]
      .-#[email protected]#*:  :+#@*:#+.
      .:.#%.*%%%%%%%-*@.::
     =#*#*+:::::::[email protected]@***#+.
   **=:::::::::::.*%+-::::-**
.=#=::::::::::::::--::::::::-#+:
FantomPocong #9564
*/

/// @author: #NonBlokMovement
/**
* #NonBlokMovement or any individuals and/or parties related directly or
* indirectly to it are not responsible for any results as a result of using this template.
*/
// Track #NonBlokMovement : https://twitter.com/search?q=%23nonblokmovement&f=live

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/PublicLibrary.sol

pragma solidity ^0.8.4;

/// @title Mencari Kabar

/** ============================================================
* Welcome to The Public Library of Mencari Kabar!
* ARTIKEL(s) sent to this contract is not owned by anyone
* and considered as a public domain. They will and always be
* available for anyone to see and access forever.

* It is possible that ERC721 tokens other than ARTIKEL(s) to be
* received in this contract as it does not specify which
* ERC721 tokens are allowed to be sent here.
================================================================ */

contract MencariKabarPublicLibrary is ERC721Holder, Context {

    address private _librarian;
    
    event OwnershipTransferred(address indexed previousLibrarian, address indexed newLibrarian);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function librarian() public view virtual returns (address) {
        return _librarian;
    }
    function _transferOwnership(address newLibrarian) internal virtual {
        address oldLibrarian = _librarian;
        _librarian = newLibrarian;
        emit OwnershipTransferred(oldLibrarian, newLibrarian);
    }
}
/*
    _  _   _   _             ____  _       _    __  __                                     _   
  _| || |_| \ | |           |  _ \| |     | |  |  \/  |                                   | |  
 |_  __  _|  \| | ___  _ __ | |_) | | ___ | | _| \  / | _____   _____ _ __ ___   ___ _ __ | |_ 
  _| || |_| . ` |/ _ \| '_ \|  _ <| |/ _ \| |/ / |\/| |/ _ \ \ / / _ \ '_ ` _ \ / _ \ '_ \| __|
 |_  __  _| |\  | (_) | | | | |_) | | (_) |   <| |  | | (_) \ V /  __/ | | | | |  __/ | | | |_ 
   |_||_| |_| \_|\___/|_| |_|____/|_|\___/|_|\_\_|  |_|\___/ \_/ \___|_| |_| |_|\___|_| |_|\__|
*/