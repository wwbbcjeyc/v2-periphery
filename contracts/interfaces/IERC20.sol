pragma solidity >=0.5.0;

/**
 * @title IERC20
 * @dev ERC20代币标准接口
 * 定义了代币的基本功能，包括转账、授权和查询余额等
 */
interface IERC20 {
    /**
     * @dev 当授权发生时触发的事件
     * @param owner 授权方地址
     * @param spender 被授权方地址
     * @param value 授权金额
     */
    event Approval(address indexed owner, address indexed spender, uint value);
    
    /**
     * @dev 当转账发生时触发的事件
     * @param from 发送方地址
     * @param to 接收方地址
     * @param value 转账金额
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev 获取代币名称
     * @return 代币名称
     */
    function name() external view returns (string memory);
    
    /**
     * @dev 获取代币符号
     * @return 代币符号
     */
    function symbol() external view returns (string memory);
    
    /**
     * @dev 获取代币小数位数
     * @return 小数位数
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev 获取代币总供应量
     * @return 总供应量
     */
    function totalSupply() external view returns (uint);
    
    /**
     * @dev 获取指定地址的代币余额
     * @param owner 地址
     * @return 余额
     */
    function balanceOf(address owner) external view returns (uint);
    
    /**
     * @dev 获取授权额度
     * @param owner 授权方地址
     * @param spender 被授权方地址
     * @return 授权金额
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @dev 授权额度
     * @param spender 被授权方地址
     * @param value 授权金额
     * @return 是否成功
     */
    function approve(address spender, uint value) external returns (bool);
    
    /**
     * @dev 转账
     * @param to 接收方地址
     * @param value 转账金额
     * @return 是否成功
     */
    function transfer(address to, uint value) external returns (bool);
    
    /**
     * @dev 从指定地址转账
     * @param from 发送方地址
     * @param to 接收方地址
     * @param value 转账金额
     * @return 是否成功
     */
    function transferFrom(address from, address to, uint value) external returns (bool);
}
