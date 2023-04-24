// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MyTokenAdvancedProxy {
    address private _currentImplementation;
    address private _admin;

    constructor(address initialImplementation, address admin) {
        require(initialImplementation != address(0), "Invalid implementation address.");
        require(admin != address(0), "Invalid admin address.");
        _currentImplementation = initialImplementation;
        _admin = admin;
    }

    fallback() external payable {
        address implementation = _getImplementation();
        require(implementation != address(0), "Invalid implementation address.");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), implementation, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return(ptr, size)}
        }
    }

    function _getImplementation() private view returns (address) {
        return _currentImplementation;
    }

    function changeImplementation(address newImplementation) public {
        require(msg.sender == _admin, "Only admin can change the implementation.");
        require(newImplementation != address(0), "Invalid implementation address.");
        _currentImplementation = newImplementation;
    }

    function getAdmin() public view returns (address) {
        return _admin;
    }

    receive() external payable {
    }
}