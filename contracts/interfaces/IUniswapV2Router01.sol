pragma solidity >=0.6.2;

/**
 * @title IUniswapV2Router01
 * @dev Uniswap V2路由器基础接口
 * 定义了添加/移除流动性、代币交换等核心功能
 */
interface IUniswapV2Router01 {
    /**
     * @dev 获取工厂合约地址
     * @return 工厂合约地址
     */
    function factory() external pure returns (address);
    
    /**
     * @dev 获取WETH合约地址
     * @return WETH合约地址
     */
    function WETH() external pure returns (address);

    /**
     * @dev 添加流动性
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param amountADesired 期望的tokenA数量
     * @param amountBDesired 期望的tokenB数量
     * @param amountAMin 最小可接受的tokenA数量
     * @param amountBMin 最小可接受的tokenB数量
     * @param to 流动性接收地址
     * @param deadline 交易截止时间
     * @return amountA 实际添加的tokenA数量
     * @return amountB 实际添加的tokenB数量
     * @return liquidity 获得的流动性代币数量
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    /**
     * @dev 添加ETH和代币的流动性
     * @param token 代币地址
     * @param amountTokenDesired 期望的代币数量
     * @param amountTokenMin 最小可接受的代币数量
     * @param amountETHMin 最小可接受的ETH数量
     * @param to 流动性接收地址
     * @param deadline 交易截止时间
     * @return amountToken 实际添加的代币数量
     * @return amountETH 实际添加的ETH数量
     * @return liquidity 获得的流动性代币数量
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    /**
     * @dev 移除流动性
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param liquidity 要移除的流动性数量
     * @param amountAMin 最小可接受的tokenA数量
     * @param amountBMin 最小可接受的tokenB数量
     * @param to 代币接收地址
     * @param deadline 交易截止时间
     * @return amountA 获得的tokenA数量
     * @return amountB 获得的tokenB数量
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    /**
     * @dev 移除ETH和代币的流动性
     * @param token 代币地址
     * @param liquidity 要移除的流动性数量
     * @param amountTokenMin 最小可接受的代币数量
     * @param amountETHMin 最小可接受的ETH数量
     * @param to 代币和ETH接收地址
     * @param deadline 交易截止时间
     * @return amountToken 获得的代币数量
     * @return amountETH 获得的ETH数量
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    /**
     * @dev 使用permit移除流动性
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param liquidity 要移除的流动性数量
     * @param amountAMin 最小可接受的tokenA数量
     * @param amountBMin 最小可接受的tokenB数量
     * @param to 代币接收地址
     * @param deadline 交易截止时间
     * @param approveMax 是否批准最大额度
     * @param v ECDSA签名参数
     * @param r ECDSA签名参数
     * @param s ECDSA签名参数
     * @return amountA 获得的tokenA数量
     * @return amountB 获得的tokenB数量
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    
    /**
     * @dev 使用permit移除ETH和代币的流动性
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
     * @return amountToken 获得的代币数量
     * @return amountETH 获得的ETH数量
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    
    /**
     * @dev 用精确数量的代币交换其他代币
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小可接受的输出代币数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     * @return amounts 每个步骤的代币数量
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    /**
     * @dev 用代币交换精确数量的其他代币
     * @param amountOut 期望获得的输出代币数量
     * @param amountInMax 最大可接受的输入代币数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     * @return amounts 每个步骤的代币数量
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    /**
     * @dev 用精确数量的ETH交换代币
     * @param amountOutMin 最小可接受的输出代币数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     * @return amounts 每个步骤的代币数量
     */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    /**
     * @dev 用代币交换精确数量的ETH
     * @param amountOut 期望获得的ETH数量
     * @param amountInMax 最大可接受的输入代币数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     * @return amounts 每个步骤的代币数量
     */
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    
    /**
     * @dev 用精确数量的代币交换ETH
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小可接受的ETH数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     * @return amounts 每个步骤的代币数量
     */
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    
    /**
     * @dev 用ETH交换精确数量的代币
     * @param amountOut 期望获得的代币数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     * @return amounts 每个步骤的代币数量
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /**
     * @dev 计算代币等价金额
     * @param amountA 资产A的金额
     * @param reserveA 资产A的储备
     * @param reserveB 资产B的储备
     * @return amountB 资产B的等价金额
     */
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    
    /**
     * @dev 计算输出金额
     * @param amountIn 输入金额
     * @param reserveIn 输入资产的储备
     * @param reserveOut 输出资产的储备
     * @return amountOut 输出金额
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    
    /**
     * @dev 计算输入金额
     * @param amountOut 输出金额
     * @param reserveIn 输入资产的储备
     * @param reserveOut 输出资产的储备
     * @return amountIn 输入金额
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    
    /**
     * @dev 计算多路径交易的输出金额
     * @param amountIn 输入金额
     * @param path 交易路径
     * @return amounts 每个步骤的金额
     */
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    /**
     * @dev 计算多路径交易的输入金额
     * @param amountOut 输出金额
     * @param path 交易路径
     * @return amounts 每个步骤的金额
     */
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
