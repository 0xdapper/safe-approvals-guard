pragma solidity ^0.8.17;

import {Guard} from "safe-contracts/base/GuardManager.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

bytes4 constant APPROVAL_SIG = bytes4(keccak256("approve(address,uint256)"));
error SafeApprovalsGuard__CannotApproveMoreThanTotalSupply();

contract SafeApprovalsGuard is Guard {
    event Event(uint) anonymous;

    function checkTransaction(
        address _to,
        uint256 /* _value */,
        bytes calldata _data,
        Enum.Operation _operation,
        uint256 /* _safeTxGas */,
        uint256 /* _baseGas */,
        uint256 /* _gasPrice */,
        address /* _gasToken */,
        address payable /* _refundReceiver */,
        bytes calldata /* _signatures */,
        address /* _msgSender */
    ) external view override {
        // If the transaction is to safe itself, don't check anything. This ensures
        // the user is always able to remove this guard from the safe even in cases
        // where the guard itself was buggy and not end up with a bricked safe.
        if (_to == msg.sender) {
            return;
        }

        _checkApproveCall(_to, _operation, _data);
    }

    function _checkApproveCall(
        address _to,
        Enum.Operation _operation,
        bytes calldata _data
    ) internal view {
        if (_data.length < 4) return;
        bytes4 msgSig = bytes4(_data[:4]);

        if (_operation == Enum.Operation.Call && msgSig == APPROVAL_SIG) {
            (bool success, bytes memory returnData) = _to.staticcall(
                abi.encodeWithSelector(ERC20(_to).totalSupply.selector)
            );

            uint totalSupply;
            if (success && returnData.length >= 32) {
                /// @solidity memory-safe-assembly
                assembly {
                    totalSupply := mload(add(returnData, 0x20))
                }

                if (_data.length >= 68) {
                    uint approvedAmount = uint(bytes32(_data[36:68]));
                    if (approvedAmount > totalSupply) {
                        revert SafeApprovalsGuard__CannotApproveMoreThanTotalSupply();
                    }
                }
            }
        }
    }

    function checkAfterExecution(
        bytes32 txHash,
        bool success
    ) external override {}
}
