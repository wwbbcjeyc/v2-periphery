pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IUniswapV2Router02.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

/**
 * @title UniswapV2Router02
 * @dev Uniswap V2 路由器的第二个版本，扩展了 V1 版本
 * 主要添加了对 fee-on-transfer 代币的支持
 * 提供了流动性添加/移除、代币交换等核心功能
 */
contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;

    // 工厂合约地址
    address public immutable override factory;
    // WETH 代币地址
    address public immutable override WETH;

    /**
     * @dev 确保交易在截止时间前完成
     * @param deadline 交易截止时间戳
     */
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    /**
     * @dev 构造函数
     * @param _factory 工厂合约地址
     * @param _WETH WETH 代币地址
     */
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    /**
     * @dev 接收 ETH 的回退函数
     * 只接受来自 WETH 合约的 ETH（通过 WETH 的 withdraw 函数）
     */
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** 添加流动性 ****
    /**
     * @dev 内部函数：计算并添加流动性
     * @param tokenA 代币 A 地址
     * @param tokenB 代币 B 地址
     * @param amountADesired 期望的代币 A 数量
     * @param amountBDesired 期望的代币 B 数量
     * @param amountAMin 代币 A 的最小数量
     * @param amountBMin 代币 B 的最小数量
     * @return amountA 实际添加的代币 A 数量
     * @return amountB 实际添加的代币 B 数量
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // 如果交易对不存在，则创建交易对
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        // 获取交易对的储备量
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            // 如果是第一次添加流动性，直接使用期望的数量
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 计算最优的代币 B 数量
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                // 确保代币 B 数量不低于最小值
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                // 计算最优的代币 A 数量
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                // 确保代币 A 数量不低于最小值
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @dev 添加流动性
     * @param tokenA 代币 A 地址
     * @param tokenB 代币 B 地址
     * @param amountADesired 期望的代币 A 数量
     * @param amountBDesired 期望的代币 B 数量
     * @param amountAMin 代币 A 的最小数量
     * @param amountBMin 代币 B 的最小数量
     * @param to 接收流动性代币的地址
     * @param deadline 交易截止时间戳
     * @return amountA 实际添加的代币 A 数量
     * @return amountB 实际添加的代币 B 数量
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
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        // 计算实际添加的代币数量
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        // 获取交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 转移代币到交易对合约
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        // 铸造流动性代币并发送给接收地址
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /**
     * @dev 添加 ETH 和代币的流动性
     * @param token 代币地址
     * @param amountTokenDesired 期望的代币数量
     * @param amountTokenMin 代币的最小数量
     * @param amountETHMin ETH 的最小数量
     * @param to 接收流动性代币的地址
     * @param deadline 交易截止时间戳
     * @return amountToken 实际添加的代币数量
     * @return amountETH 实际添加的 ETH 数量
     * @return liquidity 获得的流动性代币数量
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        // 计算实际添加的代币和 ETH 数量
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        // 获取交易对地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // 转移代币到交易对合约
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        // 存款 ETH 到 WETH 合约
        IWETH(WETH).deposit{value: amountETH}();
        // 转移 WETH 到交易对合约
        assert(IWETH(WETH).transfer(pair, amountETH));
        // 铸造流动性代币并发送给接收地址
        liquidity = IUniswapV2Pair(pair).mint(to);
        // 退还多余的 ETH
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** 移除流动性 ****
    /**
     * @dev 移除流动性
     * @param tokenA 代币 A 地址
     * @param tokenB 代币 B 地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountAMin 期望获得的代币 A 最小数量
     * @param amountBMin 期望获得的代币 B 最小数量
     * @param to 接收代币的地址
     * @param deadline 交易截止时间戳
     * @return amountA 获得的代币 A 数量
     * @return amountB 获得的代币 B 数量
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        // 获取交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 转移流动性代币到交易对合约
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        // 销毁流动性代币并获得代币
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        // 确定代币顺序
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        // 根据代币顺序分配数量
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        // 确保获得的代币数量不低于最小值
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    /**
     * @dev 移除 ETH 和代币的流动性
     * @param token 代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 期望获得的代币最小数量
     * @param amountETHMin 期望获得的 ETH 最小数量
     * @param to 接收代币和 ETH 的地址
     * @param deadline 交易截止时间戳
     * @return amountToken 获得的代币数量
     * @return amountETH 获得的 ETH 数量
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        // 移除流动性
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // 转移代币到接收地址
        TransferHelper.safeTransfer(token, to, amountToken);
        // 从 WETH 合约提取 ETH
        IWETH(WETH).withdraw(amountETH);
        // 转移 ETH 到接收地址
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @dev 使用 EIP-2612 许可移除流动性
     * @param tokenA 代币 A 地址
     * @param tokenB 代币 B 地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountAMin 期望获得的代币 A 最小数量
     * @param amountBMin 期望获得的代币 B 最小数量
     * @param to 接收代币的地址
     * @param deadline 交易截止时间戳
     * @param approveMax 是否批准最大数量
     * @param v ECDSA 签名的 v 值
     * @param r ECDSA 签名的 r 值
     * @param s ECDSA 签名的 s 值
     * @return amountA 获得的代币 A 数量
     * @return amountB 获得的代币 B 数量
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
    ) external virtual override returns (uint amountA, uint amountB) {
        // 获取交易对地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 计算批准数量
        uint value = approveMax ? uint(-1) : liquidity;
        // 使用 EIP-2612 许可
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        // 移除流动性
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /**
     * @dev 使用 EIP-2612 许可移除 ETH 和代币的流动性
     * @param token 代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 期望获得的代币最小数量
     * @param amountETHMin 期望获得的 ETH 最小数量
     * @param to 接收代币和 ETH 的地址
     * @param deadline 交易截止时间戳
     * @param approveMax 是否批准最大数量
     * @param v ECDSA 签名的 v 值
     * @param r ECDSA 签名的 r 值
     * @param s ECDSA 签名的 s 值
     * @return amountToken 获得的代币数量
     * @return amountETH 获得的 ETH 数量
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        // 获取交易对地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // 计算批准数量
        uint value = approveMax ? uint(-1) : liquidity;
        // 使用 EIP-2612 许可
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        // 移除流动性
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** 移除流动性（支持 fee-on-transfer 代币） ****
    /**
     * @dev 移除 ETH 和支持 fee-on-transfer 代币的流动性
     * @param token 代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 期望获得的代币最小数量
     * @param amountETHMin 期望获得的 ETH 最小数量
     * @param to 接收代币和 ETH 的地址
     * @param deadline 交易截止时间戳
     * @return amountETH 获得的 ETH 数量
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        // 移除流动性
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // 转移所有代币余额到接收地址（处理 fee-on-transfer）
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        // 从 WETH 合约提取 ETH
        IWETH(WETH).withdraw(amountETH);
        // 转移 ETH 到接收地址
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @dev 使用 EIP-2612 许可移除 ETH 和支持 fee-on-transfer 代币的流动性
     * @param token 代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 期望获得的代币最小数量
     * @param amountETHMin 期望获得的 ETH 最小数量
     * @param to 接收代币和 ETH 的地址
     * @param deadline 交易截止时间戳
     * @param approveMax 是否批准最大数量
     * @param v ECDSA 签名的 v 值
     * @param r ECDSA 签名的 r 值
     * @param s ECDSA 签名的 s 值
     * @return amountETH 获得的 ETH 数量
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        // 获取交易对地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // 计算批准数量
        uint value = approveMax ? uint(-1) : liquidity;
        // 使用 EIP-2612 许可
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        // 移除流动性
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** 交换 ****
    /**
     * @dev 内部函数：执行代币交换
     * @param amounts 各步骤的代币数量
     * @param path 代币路径
     * @param _to 接收最终代币的地址
     */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            // 获取当前输入和输出代币
            (address input, address output) = (path[i], path[i + 1]);
            // 确定代币顺序
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            // 获取输出数量
            uint amountOut = amounts[i + 1];
            // 根据代币顺序确定输出金额
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            // 确定下一个接收地址（如果不是最后一步，则发送到下一个交易对）
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            // 执行交换
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     * @dev 用精确数量的代币交换代币
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小输出代币数量
     * @param path 代币路径
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间戳
     * @return amounts 各步骤的代币数量
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 计算输出代币数量
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 确保输出数量不低于最小值
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 转移输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // 执行交换
        _swap(amounts, path, to);
    }

    /**
     * @dev 用代币交换精确数量的代币
     * @param amountOut 期望获得的输出代币数量
     * @param amountInMax 最大输入代币数量
     * @param path 代币路径
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间戳
     * @return amounts 各步骤的代币数量
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 计算输入代币数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 确保输入数量不超过最大值
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 转移输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // 执行交换
        _swap(amounts, path, to);
    }

    /**
     * @dev 用精确数量的 ETH 交换代币
     * @param amountOutMin 最小输出代币数量
     * @param path 代币路径（第一个必须是 WETH）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间戳
     * @return amounts 各步骤的代币数量
     */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径第一个是 WETH
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输出代币数量
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        // 确保输出数量不低于最小值
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 存款 ETH 到 WETH 合约
        IWETH(WETH).deposit{value: amounts[0]}();
        // 转移 WETH 到第一个交易对
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        // 执行交换
        _swap(amounts, path, to);
    }

    /**
     * @dev 用代币交换精确数量的 ETH
     * @param amountOut 期望获得的 ETH 数量
     * @param amountInMax 最大输入代币数量
     * @param path 代币路径（最后一个必须是 WETH）
     * @param to 接收 ETH 的地址
     * @param deadline 交易截止时间戳
     * @return amounts 各步骤的代币数量
     */
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径最后一个是 WETH
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输入代币数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 确保输入数量不超过最大值
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 转移输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // 执行交换到本合约
        _swap(amounts, path, address(this));
        // 从 WETH 合约提取 ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        // 转移 ETH 到接收地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @dev 用精确数量的代币交换 ETH
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小输出 ETH 数量
     * @param path 代币路径（最后一个必须是 WETH）
     * @param to 接收 ETH 的地址
     * @param deadline 交易截止时间戳
     * @return amounts 各步骤的代币数量
     */
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径最后一个是 WETH
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输出 ETH 数量
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 确保输出数量不低于最小值
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 转移输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // 执行交换到本合约
        _swap(amounts, path, address(this));
        // 从 WETH 合约提取 ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        // 转移 ETH 到接收地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @dev 用 ETH 交换精确数量的代币
     * @param amountOut 期望获得的输出代币数量
     * @param path 代币路径（第一个必须是 WETH）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间戳
     * @return amounts 各步骤的代币数量
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 确保路径第一个是 WETH
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 计算输入 ETH 数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 确保输入数量不超过发送的 ETH
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 存款 ETH 到 WETH 合约
        IWETH(WETH).deposit{value: amounts[0]}();
        // 转移 WETH 到第一个交易对
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        // 执行交换
        _swap(amounts, path, to);
        // 退还多余的 ETH
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** 交换（支持 fee-on-transfer 代币） ****
    /**
     * @dev 内部函数：执行支持 fee-on-transfer 代币的交换
     * @param path 代币路径
     * @param _to 接收最终代币的地址
     */
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            // 获取当前输入和输出代币
            (address input, address output) = (path[i], path[i + 1]);
            // 确定代币顺序
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            // 获取交易对合约
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // 作用域：避免栈溢出错误
                // 获取交易对储备量
                (uint reserve0, uint reserve1,) = pair.getReserves();
                // 根据代币顺序确定储备量
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                // 计算实际输入数量（处理 fee-on-transfer）
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                // 计算输出数量
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            // 根据代币顺序确定输出金额
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            // 确定下一个接收地址
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            // 执行交换
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @dev 用精确数量的代币交换代币（支持 fee-on-transfer 代币）
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小输出代币数量
     * @param path 代币路径
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间戳
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        // 转移输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        // 记录接收地址的初始余额
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // 执行交换
        _swapSupportingFeeOnTransferTokens(path, to);
        // 确保实际获得的代币数量不低于最小值
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev 用精确数量的 ETH 交换代币（支持 fee-on-transfer 代币）
     * @param amountOutMin 最小输出代币数量
     * @param path 代币路径（第一个必须是 WETH）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间戳
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        // 确保路径第一个是 WETH
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 获取输入 ETH 数量
        uint amountIn = msg.value;
        // 存款 ETH 到 WETH 合约
        IWETH(WETH).deposit{value: amountIn}();
        // 转移 WETH 到第一个交易对
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        // 记录接收地址的初始余额
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // 执行交换
        _swapSupportingFeeOnTransferTokens(path, to);
        // 确保实际获得的代币数量不低于最小值
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev 用精确数量的代币交换 ETH（支持 fee-on-transfer 代币）
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小输出 ETH 数量
     * @param path 代币路径（最后一个必须是 WETH）
     * @param to 接收 ETH 的地址
     * @param deadline 交易截止时间戳
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        // 确保路径最后一个是 WETH
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 转移输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        // 执行交换到本合约
        _swapSupportingFeeOnTransferTokens(path, address(this));
        // 获取获得的 WETH 数量
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        // 确保获得的数量不低于最小值
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 从 WETH 合约提取 ETH
        IWETH(WETH).withdraw(amountOut);
        // 转移 ETH 到接收地址
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** 库函数 ****
    /**
     * @dev 计算代币数量的报价
     * @param amountA 代币 A 的数量
     * @param reserveA 代币 A 的储备量
     * @param reserveB 代币 B 的储备量
     * @return amountB 代币 B 的数量
     */
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    /**
     * @dev 计算输出代币数量
     * @param amountIn 输入代币数量
     * @param reserveIn 输入代币的储备量
     * @param reserveOut 输出代币的储备量
     * @return amountOut 输出代币数量
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     * @dev 计算输入代币数量
     * @param amountOut 输出代币数量
     * @param reserveIn 输入代币的储备量
     * @param reserveOut 输出代币的储备量
     * @return amountIn 输入代币数量
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /**
     * @dev 计算多步骤交换的输出代币数量
     * @param amountIn 输入代币数量
     * @param path 代币路径
     * @return amounts 各步骤的代币数量
     */
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @dev 计算多步骤交换的输入代币数量
     * @param amountOut 输出代币数量
     * @param path 代币路径
     * @return amounts 各步骤的代币数量
     */
    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}

// 注意：本合约中使用了 IUniswapV2Pair 接口，但未在文件顶部导入
// 这是因为该接口在 UniswapV2Library 中已经导入和使用
