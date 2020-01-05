.PHONY: help prog_all build_all prog_fs prog_fpga clean_all

TOP_TARGET := help

help:
	@echo "Usage:"
	@echo "   REV A or B Pano (xc6slx150):"
	@echo "      make prog_all  - program SPI flash"
	@echo "      make build_all - rebuild all images from sources (optional)"
	@echo
	@echo "   REV C Pano (xc6slx100):"
	@echo "      make PLATFORM=pano-g2-c build_all"
	@echo "      make PLATFORM=pano-g2-c build_all"
	@echo ""
	@echo "  other make targets: clean_all, prog_fpga, prog_fs"
     
prog_all: prog_fs prog_fpga

clean_all:
	make -C fw/nes clean
	make -C fpga clean

build_all: clean_all
	make -C fw/nes
	make -C fw/nes init_image
	make -C fpga 2>&1 | tee build.log

prog_fs:
	make -C fpga prog_fs

prog_fpga:
	make -C fpga prog_fpga

