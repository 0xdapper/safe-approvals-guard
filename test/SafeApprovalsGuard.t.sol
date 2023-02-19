pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SafeApprovalsGuard, Enum, ERC20, SafeApprovalsGuard__CannotApproveMoreThanTotalSupply} from "src/SafeApprovalsGuard.sol";

contract ERC20Mock {
    uint public totalSupply;

    constructor(uint _totalSupply) {
        totalSupply = _totalSupply;
    }
}

bytes4 constant ERC20_TOTAL_SUPPLY_SIG = bytes4(keccak256("totalSupply()"));

contract ERC20__totalSupplyCollision {
    fallback() external {
        if (msg.sig == ERC20_TOTAL_SUPPLY_SIG) {
            assembly {
                mstore(0x00, 10)
                return(0x00, 0x01)
            }
        }
    }
}

contract NotERC20 {}

contract SafeApprovalsGuardTest is Test {
    uint totalSupply = 1e18;

    ERC20Mock erc20Mock = new ERC20Mock(totalSupply);
    ERC20__totalSupplyCollision erc20_totalSupplyCollision =
        new ERC20__totalSupplyCollision();
    NotERC20 notERC20 = new NotERC20();

    SafeApprovalsGuard guard = new SafeApprovalsGuard();

    function testCheckTransactionNotERC20(bytes memory _random) external view {
        _checkTransaction(address(erc20_totalSupplyCollision), _random);
        _checkTransaction(address(notERC20), _random);
        bytes memory _calldata = abi.encodePacked(
            ERC20.approve.selector,
            _random
        );

        _checkTransaction(address(erc20_totalSupplyCollision), _calldata);
        _checkTransaction(address(notERC20), _calldata);
    }

    function testCheckTransactionERC20() external {
        bytes memory approvalLessThanTotalSupply = abi.encodePacked(
            ERC20.approve.selector,
            abi.encode(address(0), (totalSupply * 1) / 10)
        );
        bytes memory approvalMoreThanTotalSupply = abi.encodePacked(
            ERC20.approve.selector,
            abi.encode(address(0), (totalSupply * 11) / 10)
        );

        // approval < total supply okay
        _checkTransaction(address(erc20Mock), approvalLessThanTotalSupply);

        // approval = total supply okay
        _checkTransaction(address(erc20Mock), approvalLessThanTotalSupply);

        // approval > total supply not okay
        vm.expectRevert(
            abi.encodePacked(
                SafeApprovalsGuard__CannotApproveMoreThanTotalSupply.selector
            )
        );
        _checkTransaction(address(erc20Mock), approvalMoreThanTotalSupply);
    }

    function _checkTransaction(address _to, bytes memory _data) internal view {
        guard.checkTransaction(
            _to,
            0,
            _data,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            abi.encode(),
            address(this)
        );
    }
}
