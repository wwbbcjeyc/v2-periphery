pragma solidity >=0.5.0;

/**
 * @title IUniswapV1Factory
 * @dev Uniswap V1工厂接口
 * 定义了获取代币对应的V1交易所地址的功能
 */
interface IUniswapV1Factory {
    /**
     * @dev 获取代币对应的V1交易所地址
     * @param token 代币地址
     * @return 交易所地址
     */
    function getExchange(address) external view returns (address);
}
