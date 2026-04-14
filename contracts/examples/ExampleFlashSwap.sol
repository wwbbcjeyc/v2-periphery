pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

import '../libraries/UniswapV2Library.sol';
import '../interfaces/V1/IUniswapV1Factory.sol';
import '../interfaces/V1/IUniswapV1Exchange.sol';
import '../interfaces/IUniswapV2Router01.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IWETH.sol';

/**
 * @title ExampleFlashSwap
 * @dev 闪电交换示例合约
 * 通过V2闪电贷获取代币/WETH，在V1上交换，偿还V2，并保留利润
 */
contract ExampleFlashSwap is IUniswapV2Callee {
    // V1工厂合约
    IUniswapV1Factory immutable factoryV1;
    // V2工厂合约地址
    address immutable factory;
    // WETH合约
    IWETH immutable WETH;

    /**
     * @dev 构造函数
     * @param _factory V2工厂合约地址
     * @param _factoryV1 V1工厂合约地址
     * @param router V2路由器地址
     */
    constructor(address _factory, address _factoryV1, address router) public {
        factoryV1 = IUniswapV1Factory(_factoryV1);
        factory = _factory;
        WETH = IWETH(IUniswapV2Router01(router).WETH());
    }

    /**
     * @dev 接收ETH的回退函数
     * @notice 需要接受来自任何V1交易所和WETH的ETH
     */
    receive() external payable {}

    /**
     * @dev V2闪电交换回调函数
     * @param sender 闪电交换发起者
     * @param amount0 获得的token0数量
     * @param amount1 获得的token1数量
     * @param data 附加数据
     * @notice 通过V2闪电贷获取代币/WETH，在V1上交换，偿还V2，并保留利润
     */
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountToken;
        uint amountETH;
        {
            // 避免栈溢出错误的作用域
            address token0 = IUniswapV2Pair(msg.sender).token0();
            address token1 = IUniswapV2Pair(msg.sender).token1();
            // 确保msg.sender是实际的V2交易对
            assert(msg.sender == UniswapV2Library.pairFor(factory, token0, token1));
            // 确保只获取一种代币（单向策略）
            assert(amount0 == 0 || amount1 == 0);
            // 设置交易路径
            path[0] = amount0 == 0 ? token0 : token1;
            path[1] = amount0 == 0 ? token1 : token0;
            // 计算获得的代币和ETH数量
            amountToken = token0 == address(WETH) ? amount1 : amount0;
            amountETH = token0 == address(WETH) ? amount0 : amount1;
        }

        // 确保交易对包含WETH
        assert(path[0] == address(WETH) || path[1] == address(WETH));
        // 获取非WETH代币
        IERC20 token = IERC20(path[0] == address(WETH) ? path[1] : path[0]);
        // 获取V1交易所
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(address(token)));

        if (amountToken > 0) {
            // 处理获取代币的情况
            (uint minETH) = abi.decode(data, (uint)); // V1的滑点参数，由调用者传入
            // 授权V1交易所使用代币
            token.approve(address(exchangeV1), amountToken);
            // 在V1上代币兑换ETH
            uint amountReceived = exchangeV1.tokenToEthSwapInput(amountToken, minETH, uint(-1));
            // 计算偿还V2所需的ETH数量
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
            // 确保获得的ETH足够偿还闪电贷
            assert(amountReceived > amountRequired);
            // 存入ETH获取WETH
            WETH.deposit{value: amountRequired}();
            // 向V2交易对返回WETH
            assert(WETH.transfer(msg.sender, amountRequired));
            // 将剩余的ETH发送给调用者
            (bool success,) = sender.call{value: amountReceived - amountRequired}(new bytes(0));
            assert(success);
        } else {
            // 处理获取ETH的情况
            (uint minTokens) = abi.decode(data, (uint)); // V1的滑点参数，由调用者传入
            // 提取WETH为ETH
            WETH.withdraw(amountETH);
            // 在V1上ETH兑换代币
            uint amountReceived = exchangeV1.ethToTokenSwapInput{value: amountETH}(minTokens, uint(-1));
            // 计算偿还V2所需的代币数量
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountETH, path)[0];
            // 确保获得的代币足够偿还闪电贷
            assert(amountReceived > amountRequired);
            // 向V2交易对返回代币
            assert(token.transfer(msg.sender, amountRequired));
            // 将剩余的代币发送给调用者
            assert(token.transfer(sender, amountReceived - amountRequired));
        }
    }
}
