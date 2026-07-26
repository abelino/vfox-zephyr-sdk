# vfox-zephyr-sdk

A [mise](https://mise.jdx.dev/) backend plugin for installing and managing the
Zephyr SDK or individual toolchains.

## Requirements

- [mise](https://github.com/jdx/mise) - v2026.8.1+
- [7zip](https://community.chocolatey.org/packages/7zip) (Windows) - v21.5+

## Install

```shell
mise plugins install zephyr-sdk https://github.com/abelino/vfox-zephyr-sdk.git
```

## Usage

Add one of the following configurations to `mise.toml`.

Install the full Zephyr SDK:

```toml
[tools]
"zephyr-sdk:full" = "latest"
```

Or install the Zephyr SDK with only the ARM toolchain:

```toml
[tools]
"zephyr-sdk:arm-zephyr-eabi" = "latest"
```

Select the LLVM toolchain with llvm = true (requires SDK 1.0.0 or newer):

```toml
[tools]
"zephyr-sdk:full" = { version = "latest", llvm = true }
```
