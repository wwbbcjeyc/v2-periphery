pragma solidity >=0.5.0;

/**
 * @title IUniswapV1Exchange
 * @dev Uniswap V1交易所接口
 * 定义了V1交易所的核心功能
 */
interface IUniswapV1Exchange {
    /**
     * @dev 获取指定地址的流动性代币余额
     * @param owner 地址
     * @return 余额
     */
    function balanceOf(address owner) external view returns (uint);
    
    /**
     * @dev 从指定地址转移流动性代币
     * @param from 发送方地址
     * @param to 接收方地址
     * @param value 转移数量
     * @return 是否成功
     */
    function transferFrom(address from, address to, uint value) external returns (bool);
    
    /**
     * @dev 移除流动性
     * @param amount 流动性数量
     * @param min_eth 最小可接受的ETH数量
     * @param min_tokens 最小可接受的代币数量
     * @param deadline 交易截止时间
     * @return 获得的ETH数量
     * @return 获得的代币数量
     */
    function removeLiquidity(uint, uint, uint, uint) external returns (uint, uint);
    
    /**
     * @dev 代币兑换ETH（输入代币）
     * @param tokens_sold 卖出的代币数量
     * @param min_eth 最小可接受的ETH数量
     * @param deadline 交易截止时间
     * @return 获得的ETH数量
     */
    function tokenToEthSwapInput(uint, uint, uint) external returns (uint);
    
    /**
     * @dev ETH兑换代币（输入ETH）
     * @param min_tokens 最小可接受的代币数量
     * @param deadline 交易截止时间
     * @return 获得的代币数量
     */
    function ethToTokenSwapInput(uint, uint) external payable returns (uint);
}
