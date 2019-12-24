###############################################################################
## Makefile
###############################################################################
CPU        ?= riscv

# Choice: [rv32i, rv32i_spartan6, rv32im, rv32imsu]
RISCV_CORE  ?= rv32i_spartan6

SRC_DIR       = .
SRC_DIR      += $(CORES_DIR)/core_soc/src_v
SRC_DIR      += $(CORES_DIR)/dbg_bridge/src_v
SRC_DIR      += $(CORES_DIR)/cpu/riscv/core/$(RISCV_CORE)
SRC_DIR      += $(CORES_DIR)/cpu/riscv/top_tcm_wrapper
SRC_DIR      += $(PANO_CORES_DIR)/g2/opl3/src_v

EXTRA_VFLAGS += CPU_SELECT_RISCV=1

# EXCLUDE_SRC - list of core files with local replacements
EXCLUDE_SRC += $(CORES_DIR)/core_soc/src_v/axi4lite_dist.v
EXCLUDE_SRC += $(CORES_DIR)/core_soc/src_v/core_soc.v
EXCLUDE_SRC += $(CORES_DIR)/cpu/riscv/top_tcm_wrapper/tcm_mem_ram.v

BSCAN_SPI_DIR = $(PANO_CORES_DIR)/xc3sprog

COMPRESS_BITFILE = yes
#MAP_CMDS = -w -intstyle ise -detail -ir off -ignore_keep_hierarchy -ol high

# NB: the -pr b option was removed from the default options, otherwise there 
# are timing errors
MAP_CMDS = -w -intstyle ise -detail -ir off -ignore_keep_hierarchy -timing -ol high -mt 2

# use 4 cores
PAR_CMDS = -w -intstyle ise -ol high  -mt 4

.PHONY: init_and_build

TOPDIR = ..
include $(TOPDIR)/pano/make/ise.mk

ifeq ($(PLATFORM),pano-g2-c)
   FS_IMAGE = $(PREBUILT_DIR)/dro_test_spiffs-g2-c.img
   OFFSET = 5111808
   BULK_ERASE = -e
else
   FS_IMAGE = $(PREBUILT_DIR)/dro_test_spiffs.img
   OFFSET = 9043968
endif

prog_fs:
	$(XC3SPROG) $(XC3SPROG_OPTS) $(BULK_ERASE) -I$(BSCAN_SPI_BITFILE) $(FS_IMAGE):w:$(OFFSET):bin

