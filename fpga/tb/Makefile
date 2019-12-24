###############################################################################
## Tool paths
###############################################################################

export TOPDIR = $(abspath ../..)
include $(TOPDIR)/pano/make/common.mk

VERILATOR_SRC ?= /usr/share/verilator/include
SYSTEMC_HOME  ?= /usr/local/systemc-2.3.1

TEST_IMAGE ?= $(CPU_CORE_DIR)/isa_sim/images/basic.elf

CORE       ?= rv32im
export VERILATOR_SRC
export SYSTEMC_HOME

SRC_DIR = . verilated
SRC_V_DIR = ./src_v
INCLUDE_PATH = $(CPU_CORE_DIR)/isa_sim

export SRC_DIR
export SRC_V_DIR
export RTL_INCLUDE = $(CPU_CORE_DIR)/core/$(CORE)
export INCLUDE_PATH

###############################################################################
## Makefile
###############################################################################
all: build

build:
	make -C $(CPU_CORE_DIR)/isa_sim lib
	make -f $(MAKE_DIR)/generate_verilated.mk CORE=$(CORE)
	make -f $(MAKE_DIR)/build_verilated.mk
	make -f $(MAKE_DIR)/build_sysc_tb.mk

clean:
	make -f $(MAKE_DIR)/generate_verilated.mk CORE=$(CORE) $@
	make -f $(MAKE_DIR)/build_verilated.mk $@
	make -f $(MAKE_DIR)/build_sysc_tb.mk $@
	-rm *.vcd

run: build
	./build/test.x -f $(TEST_IMAGE)