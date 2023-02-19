pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SafeApprovalsGuard} from "src/SafeApprovalsGuard.sol";

contract SafeApprovalsGuardScript is Script {
    function deploy() external {
        vm.broadcast();
        SafeApprovalsGuard guard = new SafeApprovalsGuard();
        console.log("SafeApprovalsGuard deployed at: ", address(guard));
    }
}
