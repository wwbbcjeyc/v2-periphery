pragma solidity >=0.5.0;

/**
 * @title IWETH
 * @dev WETH（包装ETH）接口
 * 定义了将ETH包装为ERC20代币以及解除包装的功能
 */
interface IWETH {
    /**
     * @dev 存入ETH并铸造WETH
     * @notice 调用时需要附带ETH
     */
    function deposit() external payable;
    
    /**
     * @dev 转账WETH
     * @param to 接收方地址
     * @param value 转账金额
     * @return 是否成功
     */
    function transfer(address to, uint value) external returns (bool);
    
    /**
     * @dev 提取ETH并销毁WETH
     * @param value 提取金额
     */
    function withdraw(uint) external;
}
