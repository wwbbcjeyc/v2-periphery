pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/lib/contracts/libraries/Babylonian.sol';
import '@uniswap/lib/contracts/libraries/FullMath.sol';

import './SafeMath.sol';
import './UniswapV2Library.sol';

/**
 * @title UniswapV2LiquidityMathLibrary
 * @dev Uniswap V2流动性数学库，处理流动性份额的计算，例如计算其在底层代币中的准确价值
 */
library UniswapV2LiquidityMathLibrary {
    // 使用SafeMath库进行安全数学运算
    using SafeMath for uint256;

    /**
     * @dev 计算利润最大化交易的方向和数量
     * @param truePriceTokenA tokenA的真实价格
     * @param truePriceTokenB tokenB的真实价格
     * @param reserveA tokenA的储备
     * @param reserveB tokenB的储备
     * @return aToB 是否从tokenA交换到tokenB
     * @return amountIn 输入金额
     */
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) pure internal returns (bool aToB, uint256 amountIn) {
        // 确定交易方向：如果储备比例与真实价格比例不符，则进行套利
        aToB = FullMath.mulDiv(reserveA, truePriceTokenB, reserveB) < truePriceTokenA;

        // 计算当前储备的乘积（不变量）
        uint256 invariant = reserveA.mul(reserveB);

        // 计算左侧值：使用巴比伦法计算平方根
        uint256 leftSide = Babylonian.sqrt(
            FullMath.mulDiv(
                invariant.mul(1000), // 乘以1000（考虑交易费）
                aToB ? truePriceTokenA : truePriceTokenB, // 根据方向选择价格
                (aToB ? truePriceTokenB : truePriceTokenA).mul(997) // 除以997（考虑0.3%交易费）
            )
        );
        // 计算右侧值
        uint256 rightSide = (aToB ? reserveA.mul(1000) : reserveB.mul(1000)) / 997;

        // 如果左侧值小于右侧值，说明不需要套利
        if (leftSide < rightSide) return (false, 0);

        // 计算需要输入的金额，使价格达到利润最大化价格
        amountIn = leftSide.sub(rightSide);
    }

    /**
     * @dev 获取套利后使价格达到利润最大化比率的储备
     * @param factory 工厂合约地址
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param truePriceTokenA tokenA的真实价格
     * @param truePriceTokenB tokenB的真实价格
     * @return reserveA 套利后的tokenA储备
     * @return reserveB 套利后的tokenB储备
     */
    function getReservesAfterArbitrage(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) view internal returns (uint256 reserveA, uint256 reserveB) {
        // 首先获取套利前的储备
        (reserveA, reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);

        // 确保储备大于0
        require(reserveA > 0 && reserveB > 0, 'UniswapV2ArbitrageLibrary: ZERO_PAIR_RESERVES');

        // 计算套利所需的金额
        (bool aToB, uint256 amountIn) = computeProfitMaximizingTrade(truePriceTokenA, truePriceTokenB, reserveA, reserveB);

        // 如果不需要套利，返回原始储备
        if (amountIn == 0) {
            return (reserveA, reserveB);
        }

        // 应用交易到储备
        if (aToB) {
            // 从tokenA交换到tokenB
            uint amountOut = UniswapV2Library.getAmountOut(amountIn, reserveA, reserveB);
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            // 从tokenB交换到tokenA
            uint amountOut = UniswapV2Library.getAmountOut(amountIn, reserveB, reserveA);
            reserveB += amountIn;
            reserveA -= amountOut;
        }
    }

    /**
     * @dev 计算给定所有交易对参数的流动性价值
     * @param reservesA tokenA的储备
     * @param reservesB tokenB的储备
     * @param totalSupply 总流动性供应量
     * @param liquidityAmount 流动性数量
     * @param feeOn 是否开启 fees
     * @param kLast 上一次的k值
     * @return tokenAAmount 流动性对应的tokenA数量
     * @return tokenBAmount 流动性对应的tokenB数量
     */
    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint kLast
    ) internal pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        // 如果开启了fees且kLast > 0，计算 fees
        if (feeOn && kLast > 0) {
            // 计算当前储备乘积的平方根
            uint rootK = Babylonian.sqrt(reservesA.mul(reservesB));
            // 计算上一次k值的平方根
            uint rootKLast = Babylonian.sqrt(kLast);
            // 如果当前rootK大于上一次的rootK，说明有 fees 产生
            if (rootK > rootKLast) {
                // 计算 fees 对应的流动性
                uint numerator1 = totalSupply;
                uint numerator2 = rootK.sub(rootKLast);
                uint denominator = rootK.mul(5).add(rootKLast);
                uint feeLiquidity = FullMath.mulDiv(numerator1, numerator2, denominator);
                // 更新总供应量
                totalSupply = totalSupply.add(feeLiquidity);
            }
        }
        // 计算流动性对应的代币数量
        return (reservesA.mul(liquidityAmount) / totalSupply, reservesB.mul(liquidityAmount) / totalSupply);
    }

    /**
     * @dev 从交易对获取所有当前参数并计算流动性数量的价值
     * @notice 注意：这可能受到操纵，例如三明治攻击。建议使用 #getLiquidityValueAfterArbitrageToPrice 传入抗操纵价格
     * @param factory 工厂合约地址
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param liquidityAmount 流动性数量
     * @return tokenAAmount 流动性对应的tokenA数量
     * @return tokenBAmount 流动性对应的tokenB数量
     */
    function getLiquidityValue(
        address factory,
        address tokenA,
        address tokenB,
        uint256 liquidityAmount
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        // 获取当前储备
        (uint256 reservesA, uint256 reservesB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        // 获取交易对合约
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        // 检查是否开启了fees
        bool feeOn = IUniswapV2Factory(factory).feeTo() != address(0);
        // 获取kLast值
        uint kLast = feeOn ? pair.kLast() : 0;
        // 获取总供应量
        uint totalSupply = pair.totalSupply();
        // 计算流动性价值
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }

    /**
     * @dev 给定两个代币tokenA和tokenB及其"真实价格"（即观察到的tokenA与tokenB的价值比率），
     * 以及流动性数量，返回以tokenA和tokenB表示的流动性价值
     * @param factory 工厂合约地址
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param truePriceTokenA tokenA的真实价格
     * @param truePriceTokenB tokenB的真实价格
     * @param liquidityAmount 流动性数量
     * @return tokenAAmount 流动性对应的tokenA数量
     * @return tokenBAmount 流动性对应的tokenB数量
     */
    function getLiquidityValueAfterArbitrageToPrice(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) internal view returns (
        uint256 tokenAAmount,
        uint256 tokenBAmount
    ) {
        // 检查是否开启了fees
        bool feeOn = IUniswapV2Factory(factory).feeTo() != address(0);
        // 获取交易对合约
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        // 获取kLast值
        uint kLast = feeOn ? pair.kLast() : 0;
        // 获取总供应量
        uint totalSupply = pair.totalSupply();

        // 确保总供应量大于等于流动性数量且流动性数量大于0
        require(totalSupply >= liquidityAmount && liquidityAmount > 0, 'ComputeLiquidityValue: LIQUIDITY_AMOUNT');

        // 获取套利后的储备
        (uint reservesA, uint reservesB) = getReservesAfterArbitrage(factory, tokenA, tokenB, truePriceTokenA, truePriceTokenB);

        // 计算流动性价值
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }
}
