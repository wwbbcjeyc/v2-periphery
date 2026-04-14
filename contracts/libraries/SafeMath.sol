pragma solidity =0.6.6;

/**
 * @title SafeMath
 * @dev 安全数学库，用于执行防溢出的数学运算
 * 来源：DappHub (https://github.com/dapphub/ds-math)
 */
library SafeMath {
    /**
     * @dev 安全加法运算
     * @param x 第一个加数
     * @param y 第二个加数
     * @return z 两数之和
     * @notice 检查加法是否溢出
     */
    function add(uint x, uint y) internal pure returns (uint z) {
        // 执行加法并检查结果是否大于等于其中一个加数，防止溢出
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    /**
     * @dev 安全减法运算
     * @param x 被减数
     * @param y 减数
     * @return z 两数之差
     * @notice 检查减法是否下溢（即结果是否为负数）
     */
    function sub(uint x, uint y) internal pure returns (uint z) {
        // 执行减法并检查结果是否小于等于被减数，防止下溢
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    /**
     * @dev 安全乘法运算
     * @param x 第一个乘数
     * @param y 第二个乘数
     * @return z 两数之积
     * @notice 检查乘法是否溢出
     */
    function mul(uint x, uint y) internal pure returns (uint z) {
        // 检查乘法是否溢出：如果y不为0，则结果除以y应等于x
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
