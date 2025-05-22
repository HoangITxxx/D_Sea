// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IntervalContract.sol";

contract FactoryContract {
    struct ContractInfo {
        address contractAddress;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }
    
    mapping(string => mapping(string => ContractInfo[])) public symbolIntervalContracts;
    mapping(string => string[]) public symbolIntervals;
    address public owner;

    event NewIntervalContract(string symbol, string interval, address contractAddress);
    event NewSymbolAdded(string symbol);
    event NewIntervalAdded(string symbol, string interval);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function _deployNewContract(string memory _symbol, string memory _interval) private returns (address) {
        IntervalContract newContract = new IntervalContract(_symbol, _interval); 
        symbolIntervalContracts[_symbol][_interval].push(
            ContractInfo({
                contractAddress: address(newContract),
                startTimestamp: block.timestamp,
                endTimestamp: 0
            })
        );
        emit NewIntervalContract(_symbol, _interval, address(newContract));
        return address(newContract);
    }

    function _ensureSymbolAndInterval(string memory _symbol, string memory _interval) private {
        bool symbolExists = symbolIntervals[_symbol].length > 0;
        if (!symbolExists) {
            emit NewSymbolAdded(_symbol);
        }

        bool intervalExists = false;
        for (uint256 i = 0; i < symbolIntervals[_symbol].length; i++) {
            if (keccak256(bytes(symbolIntervals[_symbol][i])) == keccak256(bytes(_interval))) {
                intervalExists = true;
                break;
            }
        }

        if (!intervalExists) {
            symbolIntervals[_symbol].push(_interval);
            emit NewIntervalAdded(_symbol, _interval);
            _deployNewContract(_symbol, _interval);
        }
    }

    function addKline(string memory _symbol, string memory _interval, IntervalContract.KlineInput calldata input) external onlyOwner {
        require(
            keccak256(bytes(input.symbol)) == keccak256(bytes(_symbol)),
            "Kline symbol does not match"
        );
        require(
            keccak256(bytes(input.interval)) == keccak256(bytes(_interval)),
            "Kline interval does not match"
        );

        _ensureSymbolAndInterval(_symbol, _interval);

        ContractInfo[] storage contracts = symbolIntervalContracts[_symbol][_interval];
        ContractInfo storage latestContract = contracts[contracts.length - 1];
        IntervalContract intervalContract = IntervalContract(latestContract.contractAddress);

        bool success = intervalContract.addKline(input);
        if (!success) {
            latestContract.endTimestamp = block.timestamp;
            address newContractAddr = _deployNewContract(_symbol, _interval);
            contracts.push(ContractInfo({
                contractAddress: newContractAddr,
                startTimestamp: block.timestamp,
                endTimestamp: 0
            }));
            success = IntervalContract(newContractAddr).addKline(input);
            require(success, "Failed to add kline to new contract");
        }
    }

    function getKlineData(
        string memory _symbol,
        string memory _interval,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _limit
    ) external view returns (IntervalContract.Kline[] memory) {
        require(_startTime > 0, "Start time must be greater than 0");
        require(_endTime >= _startTime, "End time must be greater than or equal to start time");
        require(_limit > 0, "Limit must be greater than 0");

        ContractInfo[] memory contracts = symbolIntervalContracts[_symbol][_interval];
        require(contracts.length > 0, "Symbol or interval not supported");

        // Đếm tổng số kline có thể lấy được
        uint256 totalKlines = 0;
        for (uint256 i = 0; i < contracts.length; i++) {
            IntervalContract intervalContract = IntervalContract(contracts[i].contractAddress);
            uint256 klineCount = intervalContract.getKlineCount();
            if (klineCount > 0) {
                IntervalContract.Kline[] memory klines = intervalContract.getKlines(0, klineCount - 1);
                for (uint256 j = 0; j < klines.length; j++) {
                    if (klines[j].timestamp >= _startTime && klines[j].timestamp <= _endTime) {
                        totalKlines++;
                    }
                }
            }
        }

        // Tạo mảng kết quả
        uint256 resultSize = totalKlines < _limit ? totalKlines : _limit;
        IntervalContract.Kline[] memory result = new IntervalContract.Kline[](resultSize);
        uint256 currentIndex = 0;

        // Duyệt từ contract mới nhất đến cũ nhất
        for (uint256 i = contracts.length; i > 0 && currentIndex < _limit; i--) {
            uint256 idx = i - 1;
            IntervalContract intervalContract = IntervalContract(contracts[idx].contractAddress);
            uint256 klineCount = intervalContract.getKlineCount();
            if (klineCount > 0) {
                IntervalContract.Kline[] memory klines = intervalContract.getKlines(0, klineCount - 1);
                for (uint256 j = klines.length; j > 0 && currentIndex < _limit; j--) {
                    uint256 klineIdx = j - 1;
                    if (klines[klineIdx].timestamp >= _startTime && klines[klineIdx].timestamp <= _endTime) {
                        result[currentIndex] = klines[klineIdx];
                        currentIndex++;
                    }
                }
            }
        }

        // Tạo mảng kết quả cuối cùng
        IntervalContract.Kline[] memory trimmedResult = new IntervalContract.Kline[](currentIndex);
        for (uint256 i = 0; i < currentIndex; i++) {
            trimmedResult[i] = result[i];
        }

        return trimmedResult;
    }

    function getIntervals(string memory _symbol) external view returns (string[] memory) {
        return symbolIntervals[_symbol];
    }
}