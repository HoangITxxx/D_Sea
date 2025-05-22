// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library KlineDataLib {
    struct CompactCandle {
        uint64 startTime;
        uint64 closeTime;
        uint256 openPrice;
        uint256 highPrice;
        uint256 lowPrice;
        uint256 closePrice;
        uint256 volume;
        bool isClosed;
    }

    enum Interval {
        S_1, MIN_1, MIN_3, MIN_5, MIN_15, MIN_30,
        HOUR_1, HOUR_2, HOUR_4, HOUR_6, HOUR_8, HOUR_12,
        DAY_1, DAY_3,
        WEEK_1,
        MONTH_1,
        COUNT 
    }
}