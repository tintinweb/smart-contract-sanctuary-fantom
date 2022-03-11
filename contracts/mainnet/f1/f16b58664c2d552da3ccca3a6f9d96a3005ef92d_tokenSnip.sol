/**
 *Submitted for verification at FtmScan.com on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

  
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract tokenSnip is Ownable {
    // Déclaration des variables
    using SafeMath for uint256;
    address wTokenGas;
    address swapRouter;

    // Initialise l'adresse du contrat de swap (à adapter selon la blockchain)
    function setSwapRouteur (address _addressSwapRouter) external onlyOwner {
        swapRouter = _addressSwapRouter;
    }

   // Initialise l'adresse du " wrapped token gas" (à adapter selon la blockchain)
    function setWTokenGas (address _addressWTokenGas) external onlyOwner {
        wTokenGas = _addressWTokenGas;
    }

    // Fonction d'achat d'un token 
        // _tokenIn est la token "stable" de la paire 
        // _tokenOut est le jeton que l'on veut acheter
        // Pour plus de simplicité (sans passer par l'utilisation d'un oracle pour la conversion en USDC), on définit notre achat en nombre de token de gas de la BC
            // => facilite les repères 
        // Améliorations envisagées : 
            // Utiliser un oracle pour récupérer les prix en USDC du token gas et faire les achats avec un montant en USDC directement
            // Calculer le e18 pour simplifier la saisie du nb de token => *(10**18)
    function swapIn (address _tokenIn, address _tokenOut, uint _amountTokenGas) external {
        // On récupère les tokens dans le contrat car c'est le contrat qui effectuera les transactions
        IERC20(wTokenGas).transferFrom(msg.sender, address(this), _amountTokenGas);

        // Déclaration d'un tableau d'adresses utilisé pour le chemin du swap
        // ie : soit _tokenIn => _tokenOut (si _tokenIn = tokenGas)
        //      soit tokenGas => _tokenIn => _tokenOut
        address[] memory path;
        uint256 amountOutMin;
        if (_tokenIn == wTokenGas) {
            // Renseignement du chemin de swap
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut; 
        } else {
            // Renseignement du chemin de swap
            path = new address[](3);
            path[0] = wTokenGas;
            path[1] = _tokenIn;
            path[2] = _tokenOut;
        }

        // Calcul du 10e18 pour faciliter la saisie
        _amountTokenGas = _amountTokenGas * (10**18);

        // On approve le token pour le montant à dépenser
        IERC20(wTokenGas).approve(swapRouter, _amountTokenGas);

        // Récupération du nombre de token minimal à obtenir durant le swap
        amountOutMin = getAmountOutMin(path, _amountTokenGas);

        // Appelle la fonction swapExactTokensForTokens
        // On utilise le timestamp du block en cours pour la limite de validité du trade
        IUniswapV2Router(swapRouter).swapExactTokensForTokens(_amountTokenGas, amountOutMin, path, msg.sender, block.timestamp);
    }

    // Fonction de vente d'un token 
        // _tokenOut est la token "stable" de la paire 
        // _tokenIn est le jeton que l'on veut vendre
        // percentage est le pourcentage souhaité de vente
    function swapOut (address _tokenIn, address _tokenOut, uint _percentage) external {
        // Déclaration des variables nécessaires
        uint256 amountTokenIn;
        uint256 amountTokenToSell;
        uint256 amountOutMin;

        // Déclaration d'un tableau d'adresses utilisé pour le chemin du swap
        // ie : soit _tokenIn => _tokenOut (si _tokenOut = tokenGas)
        //      soit _tokenIn => _tokenOut => tokenGas
        address[] memory path;
        if (_tokenOut == wTokenGas) {
            // Renseignement du chemin de swap
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut; 
        } else {
            // Renseignement du chemin de swap
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
            path[2] = wTokenGas;
        }
        
        // Récupère le nombre de token disponibles à la vente
        amountTokenIn = IERC20(_tokenIn).balanceOf(msg.sender);

        // Calcule le nombre de tokens à vendre
        amountTokenToSell = amountTokenIn * _percentage / 100;
        
        // On approve le token pour le montant à dépenser
        IERC20(_tokenIn).approve(swapRouter, amountTokenToSell);

        // Récupération du nombre de token minimal à obtenir durant le swap
        amountOutMin = getAmountOutMin(path, amountTokenToSell);

        // Appelle la fonction swapExactTokensForTokens
        // On utilise le timestamp du block en cours pour la limite de validité du trade
        IUniswapV2Router(swapRouter).swapExactTokensForTokens(amountTokenToSell, amountOutMin, path, msg.sender, block.timestamp);
    }

    // Fonction permettant de déterminer le montant de token minimal à obtenir lors du swap
    function getAmountOutMin(address[] memory _path, uint256 _amountIn) private view returns (uint256) {
        
        uint256[] memory amountOutMins = IUniswapV2Router(swapRouter).getAmountsOut(_amountIn, _path);
        return amountOutMins[_path.length -1];  
    } 

}