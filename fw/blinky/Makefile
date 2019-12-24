include ../../project.mk

TARGET       = blinky

# source to include
SRC_DIR      = .
SRC_DIR     += $(CORES_DIR)/core_soc/src_c
SRC_DIR     += $(PANO_FW_DIR)/lib/libstd

INCLUDE_PATH += ../include
INCLUDE_PATH += $(PANO_FW_DIR)/common

# build optons
OPT        = 2
ENABLE_LST = yes

include $(TOPDIR)/pano/make/c_prog.mk

