pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

/**
 * @title IUniswapV2Router02
 * @dev Uniswap V2路由器扩展接口
 * 继承自IUniswapV2Router01，添加了对fee-on-transfer代币的支持
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
    /**
     * @dev 移除ETH和代币的流动性（支持fee-on-transfer代币）
     * @param token 代币地址
     * @param liquidity 要移除的流动性数量
     * @param amountTokenMin 最小可接受的代币数量
     * @param amountETHMin 最小可接受的ETH数量
     * @param to 代币和ETH接收地址
     * @param deadline 交易截止时间
     * @return amountETH 获得的ETH数量
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    
    /**
     * @dev 使用permit移除ETH和代币的流动性（支持fee-on-transfer代币）
     * @param token 代币地址
     * @param liquidity 要移除的流动性数量
     * @param amountTokenMin 最小可接受的代币数量
     * @param amountETHMin 最小可接受的ETH数量
     * @param to 代币和ETH接收地址
     * @param deadline 交易截止时间
     * @param approveMax 是否批准最大额度
     * @param v ECDSA签名参数
     * @param r ECDSA签名参数
     * @param s ECDSA签名参数
     * @return amountETH 获得的ETH数量
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    /**
     * @dev 用精确数量的代币交换其他代币（支持fee-on-transfer代币）
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小可接受的输出代币数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    /**
     * @dev 用精确数量的ETH交换代币（支持fee-on-transfer代币）
     * @param amountOutMin 最小可接受的输出代币数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    
    /**
     * @dev 用精确数量的代币交换ETH（支持fee-on-transfer代币）
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小可接受的ETH数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
