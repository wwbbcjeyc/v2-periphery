pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

/**
 * @title UniswapV2Library
 * @dev Uniswap V2核心库，提供代币排序、价格计算、路径计算等功能
 */
library UniswapV2Library {
    // 使用SafeMath库进行安全数学运算
    using SafeMath for uint;

    /**
     * @dev 对两个代币地址进行排序
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @return token0 排序后的第一个代币地址（数值较小）
     * @return token1 排序后的第二个代币地址（数值较大）
     * @notice 确保两个代币地址不同且非零地址
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        // 确保两个代币地址不同
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        // 根据地址数值大小排序
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // 确保排序后的第一个代币地址非零
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    /**
     * @dev 使用CREATE2计算交易对合约地址
     * @param factory 工厂合约地址
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @return pair 交易对合约地址
     * @notice 无需外部调用，直接计算地址
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        // 首先对代币地址排序
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // 使用CREATE2计算地址
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff', // CREATE2前缀
                factory, // 工厂合约地址
                keccak256(abi.encodePacked(token0, token1)), // 排序后的代币地址哈希
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // 初始化代码哈希
            ))));
    }

    /**
     * @dev 获取并排序交易对的储备
     * @param factory 工厂合约地址
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @return reserveA tokenA的储备量
     * @return reserveB tokenB的储备量
     */
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        // 对代币地址排序
        (address token0,) = sortTokens(tokenA, tokenB);
        // 获取交易对合约并调用getReserves()
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        // 根据输入代币顺序返回储备
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @dev 根据储备计算等价金额
     * @param amountA 资产A的金额
     * @param reserveA 资产A的储备
     * @param reserveB 资产B的储备
     * @return amountB 资产B的等价金额
     * @notice 用于计算两种资产的兑换比例
     */
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        // 确保输入金额大于0
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        // 确保储备大于0
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // 计算等价金额：amountB = amountA * reserveB / reserveA
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /**
     * @dev 计算给定输入金额能获得的最大输出金额--已知输入求输出
     * @param amountIn 输入金额
     * @param reserveIn 输入资产的储备
     * @param reserveOut 输出资产的储备
     * @return amountOut 最大输出金额
     * @notice 考虑0.3%的交易费
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
       
        // 公式推导：
        // 恒定乘积公式：x * y = k
        // 加入手续费：只有 99.7% 进入池子
        // (x + 0.997 * Δx) * (y - Δy) = x * y
        // 解得：Δy = (0.997 * Δx * y) / (x + 0.997 * Δx)
        // 确保输入金额大于0

        // amountIn = Δx (用户要卖的数量)
        // reserveIn = x (池子里代币A的数量)
        // reserveOut = y (池子里代币B的数量)
        // amountOut = Δy (用户能得到的数量)
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        // 确保储备大于0
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // 计算扣除0.3%费用后的输入金额（997/1000）
        uint amountInWithFee = amountIn.mul(997);
        // 计算分子：amountInWithFee * reserveOut
        uint numerator = amountInWithFee.mul(reserveOut);
        // 计算分母：reserveIn * 1000 + amountInWithFee
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        // 计算输出金额
        amountOut = numerator / denominator;
    }

    /**
     * @dev 计算获得给定输出金额所需的输入金额 -- 已知输出求输入
     * @param amountOut 输出金额
     * @param reserveIn 输入资产的储备
     * @param reserveOut 输出资产的储备
     * @return amountIn 所需的输入金额
     * @notice 考虑0.3%的交易费，向上取整
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        // 公式推导：
        // (x + 0.997 * Δx) * (y - Δy) = x * y
        // 解得：Δx = (x * Δy * 1000) / ((y - Δy) * 997)
        // 确保输出金额大于0

        // amountOut = Δy (用户想得到的数量)
        // reserveIn = x
        // reserveOut = y
        // amountIn = Δx (用户需要支付的数量)
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        // 确保储备大于0
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // 计算分子：reserveIn * amountOut * 1000
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        // 计算分母：(reserveOut - amountOut) * 997
        uint denominator = reserveOut.sub(amountOut).mul(997);
        // 计算输入金额并向上取整
        amountIn = (numerator / denominator).add(1);
    }

    /**
     * @dev 计算多路径交易的输出金额
     * @param factory 工厂合约地址
     * @param amountIn 初始输入金额
     * @param path 交易路径（代币地址数组）
     * @return amounts 每个步骤的金额数组
     * @notice 从第一个代币开始，依次计算每个交易对的输出
     */
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        // 确保路径至少包含两个代币
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        // 创建金额数组
        amounts = new uint[](path.length);
        // 第一个元素为初始输入金额
        amounts[0] = amountIn;
        // 遍历路径，计算每个交易对的输出
        for (uint i; i < path.length - 1; i++) {
            // 获取当前交易对的储备
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            // 计算输出金额
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @dev 计算多路径交易所需的输入金额
     * @param factory 工厂合约地址
     * @param amountOut 最终输出金额
     * @param path 交易路径（代币地址数组）
     * @return amounts 每个步骤的金额数组
     * @notice 从最后一个代币开始，反向计算每个交易对的输入
     */
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        // 确保路径至少包含两个代币
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        // 创建金额数组
        amounts = new uint[](path.length);
        // 最后一个元素为最终输出金额
        amounts[amounts.length - 1] = amountOut;
        // 反向遍历路径，计算每个交易对的输入
        for (uint i = path.length - 1; i > 0; i--) {
            // 获取当前交易对的储备
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            // 计算输入金额
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
