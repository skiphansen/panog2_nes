ARCH         = riscv

GIT_INIT := $(shell if [ ! -e pano/.git ]; then git submodule init; git submodule update; fi)
TEMP = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TOPDIR := $(TEMP:/=)


BASE_ADDRESS  = 0x0

# hardware defines
CPU_KHZ       = 50000
EXTRA_CFLAGS += -DCPU_KHZ=$(CPU_KHZ)

# UART driver
EXTRA_CFLAGS += -DCONFIG_UARTLITE_BASE=0x92000000

# SPI driver
EXTRA_CFLAGS += -DCONFIG_SPILITE_BASE=0x93000000



