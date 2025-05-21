// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IntervalContract.sol";

contract FactoryContract {
    struct ContractInfo {
        address contractAddress;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    mapping(string => ContractInfo[]) public intervalContracts;
    string[] public intervals;

    event NewIntervalContract(string interval, address contractAddress);

    constructor(string[] memory _intervals) {
        for (uint256 i = 0; i < _intervals.length; i++) {
            intervals.push(_intervals[i]);
            _deployNewContract(_intervals[i]);
        }
    }

    function _deployNewContract(string memory _interval) private returns (address) {
        IntervalContract newContract = new IntervalContract(_interval);
        intervalContracts[_interval].push(
            ContractInfo({
                contractAddress: address(newContract),
                startTimestamp: block.timestamp,
                endTimestamp: 0
            })
        );
        emit NewIntervalContract(_interval, address(newContract));
        return address(newContract);
    }

    function addKline(string memory _interval, IntervalContract.KlineInput calldata input) external {
        ContractInfo[] storage contracts = intervalContracts[_interval];
        require(contracts.length > 0, "Interval not supported");
        require(
        keccak256(bytes(input.interval)) == keccak256(bytes(_interval)), "Kline interval does not match"
        );

        ContractInfo storage latestContract = contracts[contracts.length - 1];
        IntervalContract intervalContract = IntervalContract(latestContract.contractAddress);

        bool success = intervalContract.addKline(input);
        if (!success) {
            latestContract.endTimestamp = block.timestamp;
            address newContractAddr = _deployNewContract(_interval);
            IntervalContract(newContractAddr).addKline(input);
        }
    }

    function getKlineData(
        string memory _interval,
        uint256 _startTime,
        uint256 _endTime
    ) external view returns (IntervalContract.Kline[] memory) {
        ContractInfo[] memory contracts = intervalContracts[_interval];
        require(contracts.length > 0, "Interval not supported");

        // Nếu _startTime và _endTime không hợp lệ, lấy tất cả kline
        bool useTimeFilter = _startTime > 0 && _endTime >= _startTime;
        uint256 totalKlines = 0;

        for (uint256 i = 0; i < contracts.length; i++) {
            if (!useTimeFilter || (
                (contracts[i].endTimestamp == 0 || contracts[i].endTimestamp >= _startTime) &&
                contracts[i].startTimestamp <= _endTime
            )) {
                IntervalContract intervalContract = IntervalContract(contracts[i].contractAddress);
                totalKlines += intervalContract.getKlineCount();
            }
        }

        IntervalContract.Kline[] memory result = new IntervalContract.Kline[](totalKlines);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < contracts.length; i++) {
            if (!useTimeFilter || (
                (contracts[i].endTimestamp == 0 || contracts[i].endTimestamp >= _startTime) &&
                contracts[i].startTimestamp <= _endTime
            )) {
                IntervalContract intervalContract = IntervalContract(contracts[i].contractAddress);
                uint256 klineCount = intervalContract.getKlineCount();
                if (klineCount > 0) {
                    IntervalContract.Kline[] memory klines = intervalContract.getKlines(0, klineCount - 1);
                    for (uint256 j = 0; j < klines.length; j++) {
                        if (!useTimeFilter || (klines[j].timestamp >= _startTime && klines[j].timestamp <= _endTime)) {
                            result[currentIndex] = klines[j];
                            currentIndex++;
                        }
                    }
                }
            }
        }

        IntervalContract.Kline[] memory trimmedResult = new IntervalContract.Kline[](currentIndex);
        for (uint256 i = 0; i < currentIndex; i++) {
            trimmedResult[i] = result[i];
        }

        return trimmedResult;
    }

    function getIntervals() external view returns (string[] memory) {
        return intervals;
    }
}