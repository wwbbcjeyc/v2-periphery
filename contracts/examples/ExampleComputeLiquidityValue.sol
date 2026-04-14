pragma solidity =0.6.6;

import '../libraries/UniswapV2LiquidityMathLibrary.sol';

/**
 * @title ExampleComputeLiquidityValue
 * @dev 计算流动性价值的示例合约
 * 展示如何使用UniswapV2LiquidityMathLibrary来计算流动性价值
 */
contract ExampleComputeLiquidityValue {
    // 使用SafeMath库进行安全数学运算
    using SafeMath for uint256;

    // 工厂合约地址（不可变）
    address public immutable factory;

    /**
     * @dev 构造函数
     * @param factory_ 工厂合约地址
     */
    constructor(address factory_) public {
        factory = factory_;
    }

    /**
     * @dev 获取套利后的储备
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param truePriceTokenA tokenA的真实价格
     * @param truePriceTokenB tokenB的真实价格
     * @return reserveA 套利后的tokenA储备
     * @return reserveB 套利后的tokenB储备
     * @notice 调用UniswapV2LiquidityMathLibrary.getReservesAfterArbitrage
     */
    function getReservesAfterArbitrage(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        return UniswapV2LiquidityMathLibrary.getReservesAfterArbitrage(
            factory,
            tokenA,
            tokenB,
            truePriceTokenA,
            truePriceTokenB
        );
    }

    /**
     * @dev 计算流动性价值
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param liquidityAmount 流动性数量
     * @return tokenAAmount 流动性对应的tokenA数量
     * @return tokenBAmount 流动性对应的tokenB数量
     * @notice 调用UniswapV2LiquidityMathLibrary.getLiquidityValue
     */
    function getLiquidityValue(
        address tokenA,
        address tokenB,
        uint256 liquidityAmount
    ) external view returns (
        uint256 tokenAAmount,
        uint256 tokenBAmount
    ) {
        return UniswapV2LiquidityMathLibrary.getLiquidityValue(
            factory,
            tokenA,
            tokenB,
            liquidityAmount
        );
    }

    /**
     * @dev 计算套利后的流动性价值
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param truePriceTokenA tokenA的真实价格
     * @param truePriceTokenB tokenB的真实价格
     * @param liquidityAmount 流动性数量
     * @return tokenAAmount 流动性对应的tokenA数量
     * @return tokenBAmount 流动性对应的tokenB数量
     * @notice 调用UniswapV2LiquidityMathLibrary.getLiquidityValueAfterArbitrageToPrice
     */
    function getLiquidityValueAfterArbitrageToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) external view returns (
        uint256 tokenAAmount,
        uint256 tokenBAmount
    ) {
        return UniswapV2LiquidityMathLibrary.getLiquidityValueAfterArbitrageToPrice(
            factory,
            tokenA,
            tokenB,
            truePriceTokenA,
            truePriceTokenB,
            liquidityAmount
        );
    }

    /**
     * @dev 测试函数，测量getLiquidityValueAfterArbitrageToPrice的 gas 成本
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param truePriceTokenA tokenA的真实价格
     * @param truePriceTokenB tokenB的真实价格
     * @param liquidityAmount 流动性数量
     * @return gas成本
     */
    function getGasCostOfGetLiquidityValueAfterArbitrageToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) external view returns (
        uint256
    ) {
        // 记录调用前的gas剩余量
        uint gasBefore = gasleft();
        // 调用函数
        UniswapV2LiquidityMathLibrary.getLiquidityValueAfterArbitrageToPrice(
            factory,
            tokenA,
            tokenB,
            truePriceTokenA,
            truePriceTokenB,
            liquidityAmount
        );
        // 记录调用后的gas剩余量
        uint gasAfter = gasleft();
        // 返回消耗的gas量
        return gasBefore - gasAfter;
    }
}
