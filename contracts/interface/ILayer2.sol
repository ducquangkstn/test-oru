pragma solidity ^0.6.0;

interface ILayer2 {
    function getBlock(uint256 blockNumber) external view returns (bytes32 blockRoot);

    function getGenesisStateData()
        external
        view
        returns (
            bytes32 stateRoot,
            bytes32 looRoot,
            uint32 accountMax,
            uint48 looMax
        );
}
