pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

import '../libraries/UniswapV2OracleLibrary.sol';
import '../libraries/UniswapV2Library.sol';

/**
 * @title ExampleOracleSimple
 * @dev 固定窗口预言机
 * 每个周期重新计算整个周期的平均价格
 * 注意：价格平均值保证至少覆盖一个周期，但可能覆盖更长的周期
 */
contract ExampleOracleSimple {
    // 使用FixedPoint库进行定点数运算
    using FixedPoint for *;

    // 定义价格更新周期为24小时
    uint public constant PERIOD = 24 hours;

    // 交易对合约实例（不可变）
    IUniswapV2Pair immutable pair;
    // 交易对中的第一个代币地址（不可变）
    address public immutable token0;
    // 交易对中的第二个代币地址（不可变）
    address public immutable token1;

    // 上一次的token1相对于token0的累积价格
    uint    public price0CumulativeLast;
    // 上一次的token0相对于token1的累积价格
    uint    public price1CumulativeLast;
    // 上一次更新的区块时间戳
    uint32  public blockTimestampLast;
    // token1相对于token0的平均价格（uq112x112格式）
    FixedPoint.uq112x112 public price0Average;
    // token0相对于token1的平均价格（uq112x112格式）
    FixedPoint.uq112x112 public price1Average;

    /**
     * @dev 构造函数
     * @param factory Uniswap V2工厂合约地址
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     */
    constructor(address factory, address tokenA, address tokenB) public {
        // 通过工厂合约和代币地址计算交易对地址并实例化
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        pair = _pair;
        // 获取交易对中的代币0和代币1地址
        token0 = _pair.token0();
        token1 = _pair.token1();
        // 获取当前的累积价格值
        price0CumulativeLast = _pair.price0CumulativeLast(); // 获取当前累积价格值 (token1 / token0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // 获取当前累积价格值 (token0 / token1)
        // 声明储备变量
        uint112 reserve0;
        uint112 reserve1;
        // 获取交易对的储备和时间戳
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        // 确保交易对中有流动性
        require(reserve0 != 0 && reserve1 != 0, 'ExampleOracleSimple: NO_RESERVES');
    }

    /**
     * @dev 更新预言机价格数据
     * @notice 必须至少经过一个完整的周期（24小时）才能调用此函数
     */
    function update() external {
        // 获取当前的累积价格和时间戳
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        // 计算经过的时间
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // 允许溢出

        // 确保至少经过了一个完整的周期
        require(timeElapsed >= PERIOD, 'ExampleOracleSimple: PERIOD_NOT_ELAPSED');

        // 计算平均价格
        // 累积价格的单位是 (uq112x112价格 * 秒)，因此我们通过除以经过的时间来计算平均值
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        // 更新存储的累积价格和时间戳
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    /**
     * @dev 查询预言机价格
     * @notice 在第一次成功调用update()之前，此函数将始终返回0
     * @param token 要查询的代币地址
     * @param amountIn 输入的代币数量
     * @return amountOut 预估的输出代币数量
     */
    function consult(address token, uint amountIn) external view returns (uint amountOut) {
        // 如果输入代币是token0，则使用price0Average计算输出
        if (token == token0) {
            // 使用平均价格计算输出数量，并解码为uint144
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            // 确保输入代币是token1
            require(token == token1, 'ExampleOracleSimple: INVALID_TOKEN');
            // 使用平均价格计算输出数量，并解码为uint144
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}
