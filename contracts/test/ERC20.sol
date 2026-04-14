pragma solidity =0.6.6;

import '../libraries/SafeMath.sol';

/**
 * @title ERC20
 * @dev 标准 ERC20 代币实现
 * 包含 EIP-2612 许可功能
 */
contract ERC20 {
    using SafeMath for uint;

    // 代币名称
    string public constant name = 'Test Token';
    // 代币符号
    string public constant symbol = 'TT';
    // 小数位数
    uint8 public constant decimals = 18;
    // 总供应量
    uint  public totalSupply;
    // 地址到余额的映射
    mapping(address => uint) public balanceOf;
    // 地址到授权额度的映射
    mapping(address => mapping(address => uint)) public allowance;

    // EIP-712 域分隔符
    bytes32 public DOMAIN_SEPARATOR;
    // 许可类型哈希
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // 地址到随机数的映射（用于 EIP-2612）
    mapping(address => uint) public nonces;

    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint value);
    // 转账事件
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev 构造函数
     * @param _totalSupply 初始总供应量
     */
    constructor(uint _totalSupply) public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        // 计算 EIP-712 域分隔符
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        // 铸造初始供应量给部署者
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev 内部铸造函数
     * @param to 接收地址
     * @param value 铸造数量
     */
    function _mint(address to, uint value) internal {
        // 增加总供应量
        totalSupply = totalSupply.add(value);
        // 增加接收地址余额
        balanceOf[to] = balanceOf[to].add(value);
        // 触发转账事件（从地址0）
        emit Transfer(address(0), to, value);
    }

    /**
     * @dev 内部销毁函数
     * @param from 销毁地址
     * @param value 销毁数量
     */
    function _burn(address from, uint value) internal {
        // 减少销毁地址余额
        balanceOf[from] = balanceOf[from].sub(value);
        // 减少总供应量
        totalSupply = totalSupply.sub(value);
        // 触发转账事件（到地址0）
        emit Transfer(from, address(0), value);
    }

    /**
     * @dev 内部授权函数
     * @param owner 所有者地址
     * @param spender 被授权地址
     * @param value 授权金额
     */
    function _approve(address owner, address spender, uint value) private {
        // 设置授权额度
        allowance[owner][spender] = value;
        // 触发授权事件
        emit Approval(owner, spender, value);
    }

    /**
     * @dev 内部转账函数
     * @param from 源地址
     * @param to 目标地址
     * @param value 转账金额
     */
    function _transfer(address from, address to, uint value) private {
        // 减少源地址余额
        balanceOf[from] = balanceOf[from].sub(value);
        // 增加目标地址余额
        balanceOf[to] = balanceOf[to].add(value);
        // 触发转账事件
        emit Transfer(from, to, value);
    }

    /**
     * @dev 授权函数
     * @param spender 被授权地址
     * @param value 授权金额
     * @return 操作是否成功
     */
    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev 转账函数
     * @param to 目标地址
     * @param value 转账金额
     * @return 操作是否成功
     */
    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev 从指定地址转账函数
     * @param from 源地址
     * @param to 目标地址
     * @param value 转账金额
     * @return 操作是否成功
     */
    function transferFrom(address from, address to, uint value) external returns (bool) {
        // 如果授权额度不是无限
        if (allowance[from][msg.sender] != uint(-1)) {
            // 减少授权额度
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        // 执行转账
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev EIP-2612 许可函数
     * @param owner 所有者地址
     * @param spender 被授权地址
     * @param value 授权金额
     * @param deadline 截止时间
     * @param v ECDSA 签名的 v 值
     * @param r ECDSA 签名的 r 值
     * @param s ECDSA 签名的 s 值
     */
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        // 确保未过期
        require(deadline >= block.timestamp, 'EXPIRED');
        // 计算签名哈希
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        // 恢复签名者地址
        address recoveredAddress = ecrecover(digest, v, r, s);
        // 确保签名有效
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        // 执行授权
        _approve(owner, spender, value);
    }
}
