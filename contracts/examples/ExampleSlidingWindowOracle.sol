pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

import '../libraries/SafeMath.sol';
import '../libraries/UniswapV2Library.sol';
import '../libraries/UniswapV2OracleLibrary.sol';

/**
 * @title ExampleSlidingWindowOracle
 * @dev 滑动窗口预言机
 * 使用在窗口内收集的观察数据来提供过去的移动平均价格
 * 窗口大小为`windowSize`，精度为`windowSize / granularity`
 * 注意：这是一个单例预言机，每个参数集只需要部署一次
 * 与简单预言机不同，简单预言机每个交易对都需要部署一次
 */
contract ExampleSlidingWindowOracle {
    // 使用FixedPoint库进行定点数运算
    using FixedPoint for *;
    // 使用SafeMath库进行安全数学运算
    using SafeMath for uint;

    /**
     * @dev 观察数据结构
     */
    struct Observation {
        uint timestamp;          // 观察时间戳
        uint price0Cumulative;   // token1相对于token0的累积价格
        uint price1Cumulative;   // token0相对于token1的累积价格
    }

    // 工厂合约地址（不可变）
    address public immutable factory;
    // 移动平均计算的时间窗口大小，例如24小时
    uint public immutable windowSize;
    // 每个交易对存储的观察数据数量
    // 随着granularity从1增加，需要更频繁的更新，但移动平均会更精确
    // 平均值计算的时间间隔范围：
    //   [windowSize - (windowSize / granularity) * 2, windowSize]
    // 例如：如果窗口大小为24小时，granularity为24，预言机将返回以下期间的平均价格：
    //   [now - [22小时, 24小时], now]
    uint8 public immutable granularity;
    // 周期大小，等于windowSize / granularity
    // 虽然可以通过windowSize和granularity计算，但为了节省gas和提供信息而存储
    uint public immutable periodSize;

    // 从交易对地址到该交易对的价格观察数据列表的映射
    mapping(address => Observation[]) public pairObservations;

    /**
     * @dev 构造函数
     * @param factory_ 工厂合约地址
     * @param windowSize_ 窗口大小
     * @param granularity_ 粒度
     */
    constructor(address factory_, uint windowSize_, uint8 granularity_) public {
        // 确保粒度大于1
        require(granularity_ > 1, 'SlidingWindowOracle: GRANULARITY');
        // 确保窗口大小可以被粒度整除
        require(
            (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
            'SlidingWindowOracle: WINDOW_NOT_EVENLY_DIVISIBLE'
        );
        factory = factory_;
        windowSize = windowSize_;
        granularity = granularity_;
    }

    /**
     * @dev 返回对应于给定时间戳的观察数据索引
     * @param timestamp 时间戳
     * @return index 观察数据索引
     */
    function observationIndexOf(uint timestamp) public view returns (uint8 index) {
        uint epochPeriod = timestamp / periodSize;
        return uint8(epochPeriod % granularity);
    }

    /**
     * @dev 返回相对于当前时间窗口开始的最旧时期的观察数据
     * @param pair 交易对地址
     * @return firstObservation 最旧的观察数据
     */
    function getFirstObservationInWindow(address pair) private view returns (Observation storage firstObservation) {
        uint8 observationIndex = observationIndexOf(block.timestamp);
        // 无溢出问题。如果observationIndex + 1溢出，结果仍然为零
        uint8 firstObservationIndex = (observationIndex + 1) % granularity;
        firstObservation = pairObservations[pair][firstObservationIndex];
    }

    /**
     * @dev 更新当前时间戳的观察数据的累积价格
     * 每个观察数据每个周期最多更新一次
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     */
    function update(address tokenA, address tokenB) external {
        // 计算交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

        // 填充空观察数据数组（仅首次调用）
        for (uint i = pairObservations[pair].length; i < granularity; i++) {
            pairObservations[pair].push();
        }

        // 获取当前周期的观察数据
        uint8 observationIndex = observationIndexOf(block.timestamp);
        Observation storage observation = pairObservations[pair][observationIndex];

        // 我们只希望每个周期（即windowSize / granularity）提交一次更新
        uint timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            // 获取当前累积价格
            (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            // 更新观察数据
            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;
        }
    }

    /**
     * @dev 给定一个期间开始和结束的累积价格，以及期间长度，计算平均价格
     * 以输入金额能获得的输出金额表示
     * @param priceCumulativeStart 期间开始的累积价格
     * @param priceCumulativeEnd 期间结束的累积价格
     * @param timeElapsed 期间长度
     * @param amountIn 输入金额
     * @return amountOut 输出金额
     */
    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint amountOut) {
        // 允许溢出
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        // 计算输出金额
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    /**
     * @dev 返回给定代币使用时间范围[now - [windowSize, windowSize - periodSize * 2], now]内的移动平均价格计算的输出金额
     * 必须已经为对应于时间戳`now - windowSize`的桶调用了update
     * @param tokenIn 输入代币地址
     * @param amountIn 输入金额
     * @param tokenOut 输出代币地址
     * @return amountOut 输出金额
     */
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        // 计算交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        // 获取窗口中的第一个观察数据
        Observation storage firstObservation = getFirstObservationInWindow(pair);

        // 计算经过的时间
        uint timeElapsed = block.timestamp - firstObservation.timestamp;
        // 确保经过的时间不超过窗口大小
        require(timeElapsed <= windowSize, 'SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION');
        // 应该永远不会发生
        require(timeElapsed >= windowSize - periodSize * 2, 'SlidingWindowOracle: UNEXPECTED_TIME_ELAPSED');

        // 获取当前累积价格
        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        // 对代币地址排序
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        // 根据输入代币选择对应的价格计算
        if (token0 == tokenIn) {
            return computeAmountOut(firstObservation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(firstObservation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }
}
