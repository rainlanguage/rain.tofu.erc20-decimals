# rain.tofu.erc20-decimals

Library for reading and storing token decimals with a trust on first use (TOFU)
approach. This is used to read the decimals of ERC20 tokens and store them for
future use, under the assumption that the decimals will not change after the
first read. As this involves storing the decimals, which is a state change, there
is a read only version of the logic to simply check that decimals are either
uninitialized or consistent, without storing anything.

The caller is responsible for ensuring that read/write and read only versions
are used appropriately for their use case without introducing inconsistency.

Repo includes:

- Implementation library
- Deterministic deployments based on Zoltu with current deployed version address
  available as a constant, and expected codehash for integrity checking
- Caller library for using the Zoltu deployment as though it was an internal lib

