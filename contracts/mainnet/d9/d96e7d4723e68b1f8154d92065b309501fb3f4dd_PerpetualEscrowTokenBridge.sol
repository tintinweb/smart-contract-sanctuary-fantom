/**
 *Submitted for verification at FtmScan.com on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IERC20
{
	function approve(address _spender, uint256 _amount) external returns (bool _success);
	function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success);
}

interface IVault
{
	enum SwapKind { GIVEN_IN, GIVEN_OUT }

	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		address assetIn;
		address assetOut;
		uint256 amount;
		bytes userData;
	}

	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	function queryBatchSwap(SwapKind _kind, BatchSwapStep[] memory _swaps, address[] memory _assets, FundManagement memory _funds) external returns (int256[] memory _assetDeltas);
	function swap(SingleSwap memory _singleSwap, FundManagement memory _funds, uint256 _limit, uint256 _deadline) external payable returns (uint256 _amountCalculated);
}

contract PerpetualEscrowTokenBridge
{
	address constant VAULT = 0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce;
	address constant cLQDR = 0x814c66594a22404e101FEcfECac1012D8d75C156;
	address constant LQDR = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;
	bytes32 constant cLQDR_LQDR_POOL_ID = 0xeadcfa1f34308b144e96fcd7a07145e027a8467d000000000000000000000331;

	function calcAmountFromShares(uint256 _shares) external returns (uint256 _amount)
	{
		IVault.BatchSwapStep[] memory _swaps = new IVault.BatchSwapStep[](1);
		_swaps[0].poolId = cLQDR_LQDR_POOL_ID;
		_swaps[0].assetInIndex = 0;
		_swaps[0].assetOutIndex = 1;
		_swaps[0].amount = _shares;
		_swaps[0].userData = new bytes(0);
		address[] memory _assets = new address[](2);
		_assets[0] = cLQDR;
		_assets[1] = LQDR;
		IVault.FundManagement memory _funds;
		_funds.sender = address(this);
		_funds.fromInternalBalance = false;
		_funds.recipient = payable(msg.sender);
		_funds.toInternalBalance = false;
		int256[] memory _assetDeltas = IVault(VAULT).queryBatchSwap(IVault.SwapKind.GIVEN_IN, _swaps, _assets, _funds);
		return uint256(-_assetDeltas[1]);
	}

	function withdraw(uint256 _shares, uint256 _minAmount) external
	{
		require(IERC20(cLQDR).transferFrom(msg.sender, address(this), _shares), "transfer failure");
		require(IERC20(cLQDR).approve(VAULT, _shares), "transfer failure");
		IVault.SingleSwap memory _swap;
		_swap.poolId = cLQDR_LQDR_POOL_ID;
		_swap.kind = IVault.SwapKind.GIVEN_IN;
		_swap.assetIn = cLQDR;
		_swap.assetOut = LQDR;
		_swap.amount = _shares;
		_swap.userData = new bytes(0);
		IVault.FundManagement memory _funds;
		_funds.sender = address(this);
		_funds.fromInternalBalance = false;
		_funds.recipient = payable(msg.sender);
		_funds.toInternalBalance = false;
		IVault(VAULT).swap(_swap, _funds, _minAmount, block.timestamp);
	}
}