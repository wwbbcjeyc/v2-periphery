pragma solidity =0.6.6;

import '../interfaces/IUniswapV2Router01.sol';

/**
 * @title RouterEventEmitter
 * @dev 路由器事件发射器
 * 用于测试 Uniswap V2 路由器的交换功能
 * 通过 delegatecall 调用路由器的交换函数，并发射结果
 */
contract RouterEventEmitter {
    // 发射交换结果的事件
    event Amounts(uint[] amounts);

    /**
     * @dev 接收 ETH 的回退函数
     */
    receive() external payable {}

    /**
     * @dev 用精确数量的代币交换代币
     * @param router 路由器地址
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小输出代币数量
     * @param path 代币路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapExactTokensForTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        // 通过 delegatecall 调用路由器的 swapExactTokensForTokens 函数
        (bool success, bytes memory returnData) = router.delegatecall(abi.encodeWithSelector(
            IUniswapV2Router01(router).swapExactTokensForTokens.selector, amountIn, amountOutMin, path, to, deadline
        ));
        // 确保调用成功
        assert(success);
        // 解码返回数据并发射事件
        emit Amounts(abi.decode(returnData, (uint[])));
    }

    /**
     * @dev 用代币交换精确数量的代币
     * @param router 路由器地址
     * @param amountOut 期望获得的输出代币数量
     * @param amountInMax 最大输入代币数量
     * @param path 代币路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapTokensForExactTokens(
        address router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        // 通过 delegatecall 调用路由器的 swapTokensForExactTokens 函数
        (bool success, bytes memory returnData) = router.delegatecall(abi.encodeWithSelector(
            IUniswapV2Router01(router).swapTokensForExactTokens.selector, amountOut, amountInMax, path, to, deadline
        ));
        // 确保调用成功
        assert(success);
        // 解码返回数据并发射事件
        emit Amounts(abi.decode(returnData, (uint[])));
    }

    /**
     * @dev 用精确数量的 ETH 交换代币
     * @param router 路由器地址
     * @param amountOutMin 最小输出代币数量
     * @param path 代币路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapExactETHForTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
        // 通过 delegatecall 调用路由器的 swapExactETHForTokens 函数
        (bool success, bytes memory returnData) = router.delegatecall(abi.encodeWithSelector(
            IUniswapV2Router01(router).swapExactETHForTokens.selector, amountOutMin, path, to, deadline
        ));
        // 确保调用成功
        assert(success);
        // 解码返回数据并发射事件
        emit Amounts(abi.decode(returnData, (uint[])));
    }

    /**
     * @dev 用代币交换精确数量的 ETH
     * @param router 路由器地址
     * @param amountOut 期望获得的 ETH 数量
     * @param amountInMax 最大输入代币数量
     * @param path 代币路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapTokensForExactETH(
        address router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        // 通过 delegatecall 调用路由器的 swapTokensForExactETH 函数
        (bool success, bytes memory returnData) = router.delegatecall(abi.encodeWithSelector(
            IUniswapV2Router01(router).swapTokensForExactETH.selector, amountOut, amountInMax, path, to, deadline
        ));
        // 确保调用成功
        assert(success);
        // 解码返回数据并发射事件
        emit Amounts(abi.decode(returnData, (uint[])));
    }

    /**
     * @dev 用精确数量的代币交换 ETH
     * @param router 路由器地址
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小输出 ETH 数量
     * @param path 代币路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapExactTokensForETH(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        // 通过 delegatecall 调用路由器的 swapExactTokensForETH 函数
        (bool success, bytes memory returnData) = router.delegatecall(abi.encodeWithSelector(
            IUniswapV2Router01(router).swapExactTokensForETH.selector, amountIn, amountOutMin, path, to, deadline
        ));
        // 确保调用成功
        assert(success);
        // 解码返回数据并发射事件
        emit Amounts(abi.decode(returnData, (uint[])));
    }

    /**
     * @dev 用 ETH 交换精确数量的代币
     * @param router 路由器地址
     * @param amountOut 期望获得的输出代币数量
     * @param path 代币路径
     * @param to 接收地址
     * @param deadline 交易截止时间
     */
    function swapETHForExactTokens(
        address router,
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
        // 通过 delegatecall 调用路由器的 swapETHForExactTokens 函数
        (bool success, bytes memory returnData) = router.delegatecall(abi.encodeWithSelector(
            IUniswapV2Router01(router).swapETHForExactTokens.selector, amountOut, path, to, deadline
        ));
        // 确保调用成功
        assert(success);
        // 解码返回数据并发射事件
        emit Amounts(abi.decode(returnData, (uint[])));
    }
}
