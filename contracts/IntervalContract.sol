// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IntervalContract {
    struct Kline {
        uint256 timestamp;          // Thời gian bắt đầu kline
        uint256 endTimestamp;      // Thời gian kết thúc kline
        string symbol;             // Cặp giao dịch (BTCUSDT)
        uint256 firstTradeId;      // ID giao dịch đầu tiên
        uint256 lastTradeId;       // ID giao dịch cuối cùng
        uint256 open;              // Giá mở cửa
        uint256 high;              // Giá cao nhất
        uint256 low;               // Giá thấp nhất
        uint256 close;             // Giá đóng cửa
        uint256 volume;            // Khối lượng base asset
        uint256 numberOfTrades;    // Số lượng giao dịch
        bool isClosed;             // Kline đã đóng chưa
        uint256 quoteVolume;       // Khối lượng quote asset
        uint256 takerBuyVolume;    // Khối lượng mua base asset
        uint256 takerBuyQuoteVolume; // Khối lượng mua quote asset
    }

    struct KlineInput {
        uint256 timestamp;
        uint256 endTimestamp;
        string symbol;
        string interval;           // Interval của kline (1m, 5m, 15m, v.v.)
        uint256 firstTradeId;
        uint256 lastTradeId;
        uint256 open;
        uint256 high;
        uint256 low;
        uint256 close;
        uint256 volume;
        uint256 numberOfTrades;
        bool isClosed;
        uint256 quoteVolume;
        uint256 takerBuyVolume;
        uint256 takerBuyQuoteVolume;
    }

    Kline[] public klines;
    uint256 public constant MAX_KLINES = 2; // Giới hạn số lượng kline/contract
    address public factory;
    string public interval;

    constructor(string memory _interval) {
        factory = msg.sender;
        interval = _interval;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only Factory can call this function");
        _;
    }

    function addKline(KlineInput calldata input) external onlyFactory returns (bool) {
        // Kiểm tra interval của kline khớp với interval của contract
        require(
            keccak256(bytes(input.interval)) == keccak256(bytes(interval)),
            "Kline interval does not match contract interval"
        );
        if (klines.length >= MAX_KLINES) {
            return false; // Contract đầy
        }
        klines.push(Kline({
            timestamp: input.timestamp,
            endTimestamp: input.endTimestamp,
            symbol: input.symbol,
            firstTradeId: input.firstTradeId,
            lastTradeId: input.lastTradeId,
            open: input.open,
            high: input.high,
            low: input.low,
            close: input.close,
            volume: input.volume,
            numberOfTrades: input.numberOfTrades,
            isClosed: input.isClosed,
            quoteVolume: input.quoteVolume,
            takerBuyVolume: input.takerBuyVolume,
            takerBuyQuoteVolume: input.takerBuyQuoteVolume
        }));
        return true;
    }

    function getKlines(uint256 startIndex, uint256 endIndex) 
        external 
        view 
        returns (Kline[] memory) 
    {
        require(startIndex < klines.length, "Invalid start index");
        require(endIndex >= startIndex && endIndex < klines.length, "Invalid end index");

        uint256 length = endIndex - startIndex + 1;
        Kline[] memory result = new Kline[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = klines[startIndex + i];
        }
        return result;
    }

    function getKlineCount() external view returns (uint256) {
        return klines.length;
    }
}