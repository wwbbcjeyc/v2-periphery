pragma solidity >=0.5.0;

/**
 * @title IUniswapV2Migrator
 * @dev Uniswap V2迁移接口
 * 定义了从Uniswap V1迁移到V2的功能
 */
interface IUniswapV2Migrator {
    /**
     * @dev 从Uniswap V1迁移流动性到V2
     * @param token 代币地址
     * @param amountTokenMin 最小可接受的代币数量
     * @param amountETHMin 最小可接受的ETH数量
     * @param to 流动性接收地址
     * @param deadline 交易截止时间
     */
    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external;
}
