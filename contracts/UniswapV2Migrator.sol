pragma solidity =0.6.6;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IUniswapV2Migrator.sol';
import './interfaces/V1/IUniswapV1Factory.sol';
import './interfaces/V1/IUniswapV1Exchange.sol';
import './interfaces/IUniswapV2Router01.sol';
import './interfaces/IERC20.sol';

/**
 * @title UniswapV2Migrator
 * @dev Uniswap V2迁移合约
 * 用于从Uniswap V1迁移流动性到V2
 */
contract UniswapV2Migrator is IUniswapV2Migrator {
    // V1工厂合约
    IUniswapV1Factory immutable factoryV1;
    // V2路由器合约
    IUniswapV2Router01 immutable router;

    /**
     * @dev 构造函数
     * @param _factoryV1 V1工厂合约地址
     * @param _router V2路由器合约地址
     */
    constructor(address _factoryV1, address _router) public {
        factoryV1 = IUniswapV1Factory(_factoryV1);
        router = IUniswapV2Router01(_router);
    }

    /**
     * @dev 接收ETH的回退函数
     * @notice 需要接受来自任何V1交易所和路由器的ETH
     */
    receive() external payable {}

    /**
     * @dev 从V1迁移流动性到V2
     * @param token 代币地址
     * @param amountTokenMin 最小可接受的代币数量
     * @param amountETHMin 最小可接受的ETH数量
     * @param to 流动性接收地址
     * @param deadline 交易截止时间
     */
    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
        external
        override
    {
        // 获取V1交易所
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(token));
        // 获取调用者在V1的流动性余额
        uint liquidityV1 = exchangeV1.balanceOf(msg.sender);
        // 从调用者转移V1流动性到本合约
        require(exchangeV1.transferFrom(msg.sender, address(this), liquidityV1), 'TRANSFER_FROM_FAILED');
        // 从V1移除流动性
        (uint amountETHV1, uint amountTokenV1) = exchangeV1.removeLiquidity(liquidityV1, 1, 1, uint(-1));
        // 授权V2路由器使用代币
        TransferHelper.safeApprove(token, address(router), amountTokenV1);
        // 向V2添加流动性
        (uint amountTokenV2, uint amountETHV2,) = router.addLiquidityETH{value: amountETHV1}(
            token,
            amountTokenV1,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
        // 如果V1的代币数量多于V2使用的数量，将剩余部分返回给调用者
        if (amountTokenV1 > amountTokenV2) {
            // 重置授权为0（良好的区块链公民行为）
            TransferHelper.safeApprove(token, address(router), 0);
            // 返回剩余代币
            TransferHelper.safeTransfer(token, msg.sender, amountTokenV1 - amountTokenV2);
        } else if (amountETHV1 > amountETHV2) {
            // addLiquidityETH保证会使用所有的amountETHV1或amountTokenV1，因此这个else分支是安全的
            // 返回剩余ETH
            TransferHelper.safeTransferETH(msg.sender, amountETHV1 - amountETHV2);
        }
    }
}
