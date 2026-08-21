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

- `ITOFUTokenDecimals`, the interface the deployed singleton implements
- `LibTOFUTokenDecimalsImplementation`, the whole of the TOFU logic
- `LibTOFUTokenDecimals`, a caller library that calls the Zoltu deployment as
  though it were an internal lib, holding the deployed address as a constant and
  the expected codehash for integrity checking

## The deployment half

The concrete `TOFUTokenDecimals` singleton, the deploy script and the
deploy-pin record live in
[`rain.tofu.erc20-decimals.deploy`](https://github.com/rainlanguage/rain.tofu.erc20-decimals.deploy),
which imports this repo as the `rain-tofu-erc20-decimals` Soldeer package. The
concrete is one delegation per entry point into
`LibTOFUTokenDecimalsImplementation` and adds no behaviour of its own.

Depend on `rain-tofu-erc20-decimals` for the interface, the logic, or to call
the singleton. Depend on `rain-tofu-erc20-decimals-deploy` to deploy it or to
pin its generated deploy record.

The address and codehash constants in `LibTOFUTokenDecimals` are asserted
against real compiler output over there, where
`type(TOFUTokenDecimals).creationCode` exists. See
rainlanguage/rain.tofu.erc20-decimals#29 for the split rationale.
