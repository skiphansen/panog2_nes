###############################################################################
## Makefile
###############################################################################
CPU        ?= riscv

# Choice: [rv32i, rv32i_spartan6, rv32im, rv32imsu]
RISCV_CORE  ?= rv32i_spartan6
EXTRA_VFLAGS += CPU_SELECT_RISCV=1 PANO_PORT=1

SRC_DIR     = .
SRC_DIR     += $(shell find nes -type d)
SRC_DIR     += $(CORES_DIR)/core_soc/src_v
SRC_DIR     += $(CORES_DIR)/dbg_bridge/src_v
SRC_DIR     += $(CORES_DIR)/cpu/riscv/core/$(RISCV_CORE)
SRC_DIR     += $(CORES_DIR)/cpu/riscv/top_tcm_wrapper
SRC_DIR     += $(PANO_CORES_DIR)/async_audio/src_v

# EXCLUDE_SRC - list of core files with local replacements
EXCLUDE_SRC += $(CORES_DIR)/core_soc/src_v/axi4lite_dist.v
EXCLUDE_SRC += $(CORES_DIR)/core_soc/src_v/core_soc.v
EXCLUDE_SRC += $(CORES_DIR)/cpu/riscv/top_tcm_wrapper/tcm_mem_ram.v
EXCLUDE_SRC += nes/nes_top.v

# list of files included by other source files
EXCLUDE_SRC += nes/cmn/uart/uart_baud_clk.v
EXCLUDE_SRC += nes/cmn/uart/uart_rx.v
EXCLUDE_SRC += nes/cmn/uart/uart_tx.v
EXCLUDE_SRC += nes/cmn/fifo/fifo.v

# list of unused files
EXCLUDE_SRC += nes/dvi/tft_interface.v


COMPRESS_BITFILE = yes
#MAP_CMDS = -w -intstyle ise -detail -ir off -ignore_keep_hierarchy -ol high

# NB: the -pr b option was removed from the default options, otherwise there 
# are timing errors
MAP_CMDS = -w -intstyle ise -detail -ir off -ignore_keep_hierarchy -timing -ol high -mt 2

# use 4 cores
#PAR_CMDS = -w -intstyle ise -ol high  -mt 4

.PHONY: init_and_build

include ../project.mk
include $(TOPDIR)/pano/make/ise.mk

.PHONY: filesystem filesystems prog_all build_all prog_fs prog_fpga clean_all

filesystem: $(FS_IMAGE)

filesystems: $(G2_FS) $(G2_C_FS)

$(G2_FS): $(MKSPIFFS)
	$(Q)$(MKSPIFFS)  -c $(GAMES_DIR) -b 131072 -p 256 -s 7733248 $@ > $(TTY)

$(G2_C_FS): $(MKSPIFFS)
	$(Q)$(MKSPIFFS) -c $(GAMES_DIR) -b 65536 -p 256 -s 3276800 $@ > $(TTY)

prog_fs:
	$(XC3SPROG) $(XC3SPROG_OPTS) $(BULK_ERASE) -I$(BSCAN_SPI_BITFILE) $(FS_IMAGE):w:$(OFFSET):bin

