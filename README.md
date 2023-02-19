# SafeApprovalsGuard

`SafeApprovalsGuard` is a [safe guard](https://docs.gnosis-safe.io/learn/safe-tools/guards) implementation
for preventing infinite ERC20 approvals from being made.

It does so by checking if approved amount is greater than the token total supply.
It also skips checking on txs sent by the safe itself i.e. `to == msg.sender`
which ensures the safe is always able to unset this guard and not brick it in case
of any bug discovery.
