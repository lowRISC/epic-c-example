# RISC-V Embedded PIC Demo

## Overview

lowRISC is working on a specification and [prototype toolchain implementation](https://github.com/lowRISC/llvm-project/commits/epic) of an Embedded PIC (ePIC) ABI for RISC-V.

This repository showcases how to use the work-in-progress ePIC toolchain implementation. It contains an example of how to create fully relocatable RISC-V apps that require only a simple runtime loader. To demonstrate the relocatability, the repository also contains a simple kernel that loads and relocates the example app.

- The kernel has its entry point in `kernel.c`.
- The current example loadable app is CoreMark.

The example runs in spike (riscv-isa-sim) and simulates a system with both SRAM and Flash memory. The kernel image embeds the ELF files it will load at arbitrary addresses during system execution. The steps to load an app are:

- First the kernel simulates programming the Flash memory with the contents of the app that would be programmed into Flash in an actual embedded system.
- Then a relocating loader, adapted from libtock-c crt0, loads the app from the simulated Flash into the simulated SRAM and relocates it. The relocation process includes adjusting the Global Offset Table (GOT) and applying simple relocations to the data section.
- The GP register (the PIC base) is set to point to the app's SRAM base address.
- Control is transferred to the just loaded app and it starts running.

## Building and Running

Build requirements:

- spike (riscv-isa-sim)
- xxd
- LLVM build dependencies

The dependencies may be built and installed manually or the provided [Dockerfile](Dockerfile) can be used to set up a container with the dependencies pre-installed.

Use `make` to build and run everything.

The Clang/LLVM toolchain with ePIC support is automatically built as part of this example.

## Licensing

Unless otherwise noted, everything in this repository is covered by the Apache License, Version 2.0 (see [LICENSE](LICENSE) for full text).

This repository contains code and linker scripts adapted from the Tock OS project, namely from [libtock-c](https://github.com/tock/libtock-c). Those artifacts are licensed under either of:

- Apache License, Version 2.0
  ([LICENSE](LICENSE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT license
  (http://opensource.org/licenses/MIT)

This repository also contains code from the CoreMark benchmark, which is also licensed under the Apache License, Version 2.0 ([LICENSE](LICENSE)).
