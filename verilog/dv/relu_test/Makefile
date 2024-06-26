PWDD := $(shell pwd)
BLOCKS := $(shell basename $(PWDD))

# ---- Include Partitioned Makefiles ----

CONFIG = caravel_user_project
 
include $(MCW_ROOT)/verilog/dv/make/env.makefile
include $(MCW_ROOT)/verilog/dv/make/var.makefile
include $(MCW_ROOT)/verilog/dv/make/cpu.makefile
include $(MCW_ROOT)/verilog/dv/make/sim.makefile

# Testbench files
VERILOG_FILES = $(PWDD)/relu_tb.v
VERILOG_FILES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_FILES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# User project files
VERILOG_FILES += $(CARAVEL_ROOT)/verilog/rtl/user_project_wrapper.v
VERILOG_FILES += $(USER_PROJECT_VERILOG)/rtl/kws_wrapper.v
VERILOG_FILES += $(USER_PROJECT_VERILOG)/rtl/relu.v
VERILOG_FILES += $(USER_PROJECT_VERILOG)/rtl/kws_fsm.v

# RISCV GCC
GCC_WARNS := -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic

# C files
CFLAGS := -O0 -g $(GCC_WARNS)
C_FILES := $(PWDD)/relu_test.c

.PHONY: verify clean

verify: $(VERILOG_FILES) $(C_FILES)
	iverilog -o sim.vvp $(VERILOG_FILES)
	vvp sim.vvp
	riscv32-unknown-elf-gcc $(CFLAGS) -I$(CARAVEL_ROOT) -I$(CARAVEL_ROOT)/firmware -o relu_test.elf $(C_FILES)
	riscv32-unknown-elf-objdump -D relu_test.elf > relu_test.lst

clean:
	rm -f *.vvp *.vcd *.elf *.lst *.hex