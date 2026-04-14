pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

/**
 * @title UniswapV2OracleLibrary
 * @dev Uniswap V2预言机库，提供计算平均价格的辅助方法
 */
library UniswapV2OracleLibrary {
    // 使用FixedPoint库进行定点数运算
    using FixedPoint for *;

    /**
     * @dev 获取当前区块时间戳，限制在uint32范围内
     * @return 当前区块时间戳（uint32格式）
     * @notice 返回值范围：[0, 2**32 - 1]
     */
    function currentBlockTimestamp() internal view returns (uint32) {
        // 对当前区块时间戳取模，确保结果在uint32范围内
        return uint32(block.timestamp % 2 ** 32);
    }

    /**
     * @dev 使用反事实方法生成累积价格，以节省gas并避免调用sync()
     * @param pair 交易对合约地址
     * @return price0Cumulative token1相对于token0的累积价格
     * @return price1Cumulative token0相对于token1的累积价格
     * @return blockTimestamp 当前区块时间戳
     */
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        // 获取当前区块时间戳
        blockTimestamp = currentBlockTimestamp();
        // 获取交易对存储的最后累积价格
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // 如果自上次更新以来时间已流逝，模拟累积价格值
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // 计算经过的时间（允许溢出）
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // 计算并累加价格（允许溢出）
            // 反事实计算：根据当前储备计算价格并乘以经过的时间
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}
