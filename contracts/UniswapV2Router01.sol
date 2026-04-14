pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './libraries/UniswapV2Library.sol';
import './interfaces/IUniswapV2Router01.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

/**
 * @title UniswapV2Router01
 * @dev Uniswap V2路由器基础实现
 * 提供添加/移除流动性和代币交换功能
 */
contract UniswapV2Router01 is IUniswapV2Router01 {
    // 工厂合约地址（不可变）
    address public immutable override factory;
    // WETH合约地址（不可变）
    address public immutable override WETH;

    /**
     * @dev 确保交易未过期的修饰器
     * @param deadline 交易截止时间
     */
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    /**
     * @dev 构造函数
     * @param _factory 工厂合约地址
     * @param _WETH WETH合约地址
     */
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    /**
     * @dev 接收ETH的回退函数
     * @notice 只接受来自WETH合约的ETH
     */
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** 添加流动性 ****
    /**
     * @dev 内部添加流动性函数
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param amountADesired 期望的tokenA数量
     * @param amountBDesired 期望的tokenB数量
     * @param amountAMin 最小可接受的tokenA数量
     * @param amountBMin 最小可接受的tokenB数量
     * @return amountA 实际添加的tokenA数量
     * @return amountB 实际添加的tokenB数量
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        // 如果交易对不存在，则创建它
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        // 获取交易对的储备
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        // 如果是首次添加流动性
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 计算最优的tokenB数量
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                // 确保最优数量不小于最小可接受数量
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                // 计算最优的tokenA数量
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                // 确保最优数量不小于最小可接受数量
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
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
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        // 计算实际添加的代币数量
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        // 计算交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 从调用者转移代币到交易对
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        // 铸造流动性代币
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    
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
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        // 计算实际添加的代币和ETH数量
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        // 计算交易对地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // 从调用者转移代币到交易对
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        // 存入ETH获取WETH
        IWETH(WETH).deposit{value: amountETH}();
        // 将WETH转移到交易对
        assert(IWETH(WETH).transfer(pair, amountETH));
        // 铸造流动性代币
        liquidity = IUniswapV2Pair(pair).mint(to);
        // 退还多余的ETH
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    // **** 移除流动性 ****
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
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        // 计算交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 将流动性转移到交易对
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        // 销毁流动性代币并获取代币
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        // 对代币地址排序
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        // 根据输入顺序返回代币数量
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        // 确保获得的代币数量不小于最小可接受数量
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    
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
    ) public override ensure(deadline) returns (uint amountToken, uint amountETH) {
        // 调用removeLiquidity函数
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // 将代币转移给接收地址
        TransferHelper.safeTransfer(token, to, amountToken);
        // 提取WETH为ETH
        IWETH(WETH).withdraw(amountETH);
        // 将ETH转移给接收地址
        TransferHelper.safeTransferETH(to, amountETH);
    }
    
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
    ) external override returns (uint amountA, uint amountB) {
        // 计算交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 计算批准额度
        uint value = approveMax ? uint(-1) : liquidity;
        // 调用permit函数
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        // 调用removeLiquidity函数
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    
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
    ) external override returns (uint amountToken, uint amountETH) {
        // 计算交易对地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // 计算批准额度
        uint value = approveMax ? uint(-1) : liquidity;
        // 调用permit函数
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        // 调用removeLiquidityETH函数
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** 交换 ****
    /**
     * @dev 内部交换函数
     * @param amounts 每个步骤的金额
     * @param path 交易路径
     * @param _to 接收地址
     * @notice 要求初始金额已经发送到第一个交易对
     */
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            // 确定接收地址：如果不是最后一步，接收地址是下一个交易对；否则是最终接收地址
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            // 执行交换
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    
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
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        // 计算输出金额
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 确保输出金额不小于最小可接受数量
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 从调用者转移代币到第一个交易对
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        // 执行交换
        _swap(amounts, path, to);
    }
    
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
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        // 计算输入金额
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 确保输入金额不大于最大可接受数量
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 从调用者转移代币到第一个交易对
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        // 执行交换
        _swap(amounts, path, to);
    }
    
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
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径的第一个代币是WETH
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输出金额
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        // 确保输出金额不小于最小可接受数量
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 存入ETH获取WETH
        IWETH(WETH).deposit{value: amounts[0]}();
        // 将WETH转移到第一个交易对
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        // 执行交换
        _swap(amounts, path, to);
    }
    
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
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径的最后一个代币是WETH
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输入金额
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 确保输入金额不大于最大可接受数量
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 从调用者转移代币到第一个交易对
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        // 执行交换，接收地址为本合约
        _swap(amounts, path, address(this));
        // 提取WETH为ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        // 将ETH转移给接收地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    
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
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径的最后一个代币是WETH
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输出金额
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 确保输出金额不小于最小可接受数量
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 从调用者转移代币到第一个交易对
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        // 执行交换，接收地址为本合约
        _swap(amounts, path, address(this));
        // 提取WETH为ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        // 将ETH转移给接收地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    
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
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径的第一个代币是WETH
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输入金额
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 确保输入金额不大于发送的ETH数量
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 存入ETH获取WETH
        IWETH(WETH).deposit{value: amounts[0]}();
        // 将WETH转移到第一个交易对
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        // 执行交换
        _swap(amounts, path, to);
        // 退还多余的ETH
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
    }

    /**
     * @dev 计算代币等价金额
     * @param amountA 资产A的金额
     * @param reserveA 资产A的储备
     * @param reserveB 资产B的储备
     * @return amountB 资产B的等价金额
     */
    function quote(uint amountA, uint reserveA, uint reserveB) public pure override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    /**
     * @dev 计算输出金额
     * @param amountIn 输入金额
     * @param reserveIn 输入资产的储备
     * @param reserveOut 输出资产的储备
     * @return amountOut 输出金额
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure override returns (uint amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     * @dev 计算输入金额
     * @param amountOut 输出金额
     * @param reserveIn 输入资产的储备
     * @param reserveOut 输出资产的储备
     * @return amountIn 输入金额
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure override returns (uint amountIn) {
        return UniswapV2Library.getAmountOut(amountOut, reserveIn, reserveOut);
    }

    /**
     * @dev 计算多路径交易的输出金额
     * @param amountIn 输入金额
     * @param path 交易路径
     * @return amounts 每个步骤的金额
     */
    function getAmountsOut(uint amountIn, address[] memory path) public view override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @dev 计算多路径交易的输入金额
     * @param amountOut 输出金额
     * @param path 交易路径
     * @return amounts 每个步骤的金额
     */
    function getAmountsIn(uint amountOut, address[] memory path) public view override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}
