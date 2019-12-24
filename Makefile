.PHONY: help prog_all build_all prog_fs prog_fpga clean_all

help:
	@echo "Usage:"
	@echo "   REV A or B Pano (xc6slx150):"
	@echo "      make prog_all  - program SPI flash"
	@echo "      make build_all - rebuild all images from sources (optional)"
	@echo
	@echo "   REV C Pano (xc6slx100):"
	@echo "      make PLATFORM=pano-g2-c prog_all"
	@echo "      make PLATFORM=pano-g2-c build_all"
	@echo "  other make targets: prog_fpga, prog_fs, clean_all"
     
prog_all:
	make -C fpga prog_fs
	make -C fpga prog_fpga

build_all:
	make -C fw/blinky init_image
	make -C fpga

prog_fs:
	make -C fpga prog_fs

prog_fpga:
	make -C fpga prog_fpga

clean_all:
	make -C fw/imfplay_port clean
	make -C fpga clean

