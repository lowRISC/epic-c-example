LLVM=$(PWD)/llvm-project/build
CLANG=$(LLVM)/bin/clang

ISA=rv32imc

SPIKE=spike

KERNEL_CFLAGS=--target=riscv32 -march=$(ISA) -O3 -DKERNEL

APP_CFLAGS=--target=riscv32 -march=$(ISA) -O3 -fepic
CM_CFLAGS=$(APP_CFLAGS) -I. -Icoremark -I coremark-port -DCOMPILER_FLAGS='"$(APP_CFLAGS)"' -DITERATIONS=100

run: kernel
#       We make the entire address space available (except the first 2 pages)
#       so that we can relocate the loadable apps anywhere. Just make sure the
#       app addresses don't collide with the kernel.
	$(SPIKE) --isa=$(ISA) -m0x00002000:0xFFFE000,0x10000000:0x70000000,0x80000000:0x80000000 kernel

$(CLANG):
	git clone -b ot-llvm-16-hardening --depth=1 https://github.com/lowRISC/llvm-project.git
	mkdir llvm-project/build
	cd llvm-project/build && cmake ../llvm -G Ninja -DCMAKE_BUILD_TYPE="Debug" -DBUILD_SHARED_LIBS=True -DLLVM_USE_SPLIT_DWARF=True -DLLVM_BUILD_TESTS=False -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_ENABLE_LLD=True -DLLVM_APPEND_VC_REV=False -DLLVM_TARGETS_TO_BUILD="RISCV" -DLLVM_ENABLE_PROJECTS="clang;lld" && ninja

kernel: $(CLANG) Makefile kernel.lds init.S kernel.c cm.h htif.c htif.h addrs.h elf.c elf.h util.c util.h
	$(CLANG) $(KERNEL_CFLAGS) -c init.S
	$(CLANG) $(KERNEL_CFLAGS) -c kernel.c
	$(CLANG) $(KERNEL_CFLAGS) -c htif.c
	$(CLANG) $(KERNEL_CFLAGS) -c elf.c
	$(CLANG) $(KERNEL_CFLAGS) -c util.c
	$(CLANG) --target=riscv32 -fuse-ld=$(LLVM)/bin/ld.lld -nostdlib -static -Wl,-T,kernel.lds -o kernel init.o kernel.o htif.o elf.o util.o

coremark:
	git clone https://github.com/eembc/coremark.git

cm: $(CLANG) Makefile coremark app.lds htif.c htif.h addrs.h crt0.S coremark-port/core_portme.c coremark-port/core_portme.h coremark-port/cvt.c coremark-port/ee_printf.c coremark/core_list_join.c coremark/core_main.c coremark/core_matrix.c coremark/core_state.c coremark/core_util.c
	$(CLANG) $(CM_CFLAGS) -c htif.c -o htif_epic.o
	$(CLANG) $(CM_CFLAGS) -c crt0.S -o crt0.o
	$(CLANG) $(CM_CFLAGS) -c coremark-port/core_portme.c
	$(CLANG) $(CM_CFLAGS) -c coremark-port/cvt.c
	$(CLANG) $(CM_CFLAGS) -c coremark-port/ee_printf.c
	$(CLANG) $(CM_CFLAGS) -c coremark/core_list_join.c
	$(CLANG) $(CM_CFLAGS) -c coremark/core_main.c
	$(CLANG) $(CM_CFLAGS) -c coremark/core_matrix.c
	$(CLANG) $(CM_CFLAGS) -c coremark/core_state.c
	$(CLANG) $(CM_CFLAGS) -c coremark/core_util.c
	$(CLANG) --target=riscv32 -fuse-ld=$(LLVM)/bin/ld.lld -nostdlib -static -Wl,-T,app.lds -o cm htif_epic.o crt0.o core_portme.o cvt.o ee_printf.o core_list_join.o core_main.o core_matrix.o core_state.o core_util.o -Wl,-pie

cm.h: cm
	xxd -i cm cm.h

clean:
	rm -f *.o
	rm -f kernel
	rm -f cm cm.h

.PHONY: run clean
