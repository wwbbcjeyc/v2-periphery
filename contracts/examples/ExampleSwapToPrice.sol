pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/Babylonian.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import '../libraries/UniswapV2LiquidityMathLibrary.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IUniswapV2Router01.sol';
import '../libraries/SafeMath.sol';
import '../libraries/UniswapV2Library.sol';

/**
 * @title ExampleSwapToPrice
 * @dev 交换到指定价格的示例合约
 * 根据外部真实价格进行利润最大化的交易
 */
contract ExampleSwapToPrice {
    // 使用SafeMath库进行安全数学运算
    using SafeMath for uint256;

    // 路由器合约（不可变）
    IUniswapV2Router01 public immutable router;
    // 工厂合约地址（不可变）
    address public immutable factory;

    /**
     * @dev 构造函数
     * @param factory_ 工厂合约地址
     * @param router_ 路由器合约地址
     */
    constructor(address factory_, IUniswapV2Router01 router_) public {
        factory = factory_;
        router = router_;
    }

    /**
     * @dev 交换一定数量的代币，使得交易在给定外部真实价格的情况下利润最大化
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param truePriceTokenA tokenA的真实价格
     * @param truePriceTokenB tokenB的真实价格
     * @param maxSpendTokenA 最大可花费的tokenA数量
     * @param maxSpendTokenB 最大可花费的tokenB数量
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间
     * @notice 真实价格以tokenA与tokenB的比率表示
     * @notice 调用者必须授权此合约花费打算交换的代币
     */
    function swapToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 maxSpendTokenA,
        uint256 maxSpendTokenB,
        address to,
        uint256 deadline
    ) public {
        // 真实价格以比率表示，因此两个值都必须非零
        require(truePriceTokenA != 0 && truePriceTokenB != 0, "ExampleSwapToPrice: ZERO_PRICE");
        // 调用者可以为其中一个指定0，表示只在一个方向交换，但不能两个都为0
        require(maxSpendTokenA != 0 || maxSpendTokenB != 0, "ExampleSwapToPrice: ZERO_SPEND");

        bool aToB; // 交易方向
        uint256 amountIn; // 输入金额
        {
            // 获取交易对的储备
            (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
            // 计算利润最大化的交易方向和金额
            (aToB, amountIn) = UniswapV2LiquidityMathLibrary.computeProfitMaximizingTrade(
                truePriceTokenA, truePriceTokenB,
                reserveA, reserveB
            );
        }

        // 确保输入金额大于0
        require(amountIn > 0, 'ExampleSwapToPrice: ZERO_AMOUNT_IN');

        // 不超过允许的最大花费
        uint256 maxSpend = aToB ? maxSpendTokenA : maxSpendTokenB;
        if (amountIn > maxSpend) {
            amountIn = maxSpend;
        }

        // 确定输入和输出代币
        address tokenIn = aToB ? tokenA : tokenB;
        address tokenOut = aToB ? tokenB : tokenA;
        // 从调用者转移代币到本合约
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        // 授权路由器使用代币
        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        // 创建交易路径
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // 执行交换
        router.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin: 我们可以跳过计算这个数字，因为数学已经过测试
            path,
            to,
            deadline
        );
    }
}
