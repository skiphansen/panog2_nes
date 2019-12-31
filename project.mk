TEMP = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TOPDIR := $(TEMP:/=)

GIT_INIT := $(shell if [ ! -e $(TOPDIR)/pano/.git ]; then echo "updating submodules"> /dev/stderr;git submodule init; git submodule update; fi)

ARCH         = riscv
BASE_ADDRESS  = 0x0

# hardware defines
CPU_KHZ       = 50000
EXTRA_CFLAGS += -DCPU_KHZ=$(CPU_KHZ)

# UART driver
EXTRA_CFLAGS += -DCONFIG_UARTLITE_BASE=0x92000000

# SPI driver
EXTRA_CFLAGS += -DCONFIG_SPILITE_BASE=0x93000000

# file system
PREBUILT  := $(TOPDIR)/prebuilt
G2_FS 	  := $(PREBUILT)/nes_spiffs.img
G2_C_FS   := $(PREBUILT)/nes_spiffs-g2-c.img
GAMES_DIR := $(TOPDIR)/roms/game_roms/supported

ifeq ($(PLATFORM),pano-g2-c)
   FS_IMAGE = $(G2_C_FS)
   OFFSET = 5111808
   BULK_ERASE = -e
else
   FS_IMAGE = $(G2_FS)
   OFFSET = 9043968
endif
