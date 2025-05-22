// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IntervalContract {
    struct Kline {
        uint256 timestamp;
        uint256 endTimestamp;
        string symbol;
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

    struct KlineInput {
        uint256 timestamp;
        uint256 endTimestamp;
        string symbol;
        string interval;
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
    uint256 public constant MAX_KLINES = 2;
    address public factory;
    string public symbol;
    string public interval;
    // bool public isActive = true;

    event ContractFull(uint256 timestamp);

    constructor(string memory _symbol, string memory _interval) {
        factory = msg.sender;
        symbol = _symbol;
        interval = _interval;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only Factory can call this function");
        _;
    }

    // modifier onlyActive() {
    //     require(isActive, "Contract is deactivated");
    //     _;
    // }

    // Chỉ giữ addKline
    function addKline(KlineInput calldata input) external onlyFactory returns (bool) {
        require(
            keccak256(bytes(input.interval)) == keccak256(bytes(interval)),
            "Kline interval does not match contract interval"
        );
        require(
            keccak256(bytes(input.symbol)) == keccak256(bytes(symbol)),
            "Kline symbol does not match contract symbol"
        );
        require(input.timestamp < input.endTimestamp, "End timestamp must be greater than start timestamp");
        require(input.high >= input.low, "High must be greater than or equal to low");
        require(input.open > 0 && input.close > 0, "Open and close must be positive");

        if (klines.length >= MAX_KLINES) {
            emit ContractFull(block.timestamp);
            return false;
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

    function getSymbol() external view returns (string memory) {
        return symbol;
    }

    function getInterval() external view returns (string memory) {
        return interval;
    }

    // function deactivate() external onlyFactory {
    //     isActive = false;
    // }
}