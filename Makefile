.PHONY: help prog_all build_all prog_fs prog_fpga clean_all

TOP_TARGET := help

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
     
include ./project.mk
include $(TOPDIR)/pano/make/common.mk

