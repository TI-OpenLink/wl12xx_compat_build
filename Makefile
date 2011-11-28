################################################################################
#
# Makefile
#
# Date:	October 2011
#
# Copyright (C) 2011 Texas Instruments Incorporated - http://www.ti.com/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# 	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and  
# limitations under the License.
#
################################################################################

MAKEFLAGS += --no-print-directory
SHELL=/bin/bash

# project definitions
WL12xx_VER:=R4.0.xx
TRASH_DIR:=$(PWD)/.trash
BUILD_DIR:=$(PWD)/build
OUTPUT_DIR:=$(PWD)/output
COMPAT_DIR:=$(BUILD_DIR)/compat
COMAPT_WIRELESS_DIR:=$(BUILD_DIR)/compat-wireless

SCRIPTS_DIR:=$(PWD)/scripts

# baseline definitions
BASE_RELEASE_DIR:=/data/wlan_wcs_android/Android/Release/nlcp.Rx.L27.INC1.13.1-GB
BASE_COMPAT_DIR:=$(BASE_RELEASE_DIR)/compat/$(WL12xx_VER)
COMPAT_BASE_DIR:=$(BASE_COMPAT_DIR)/compat
COMAPT_WIRELESS_BASE_DIR:=$(BASE_COMPAT_DIR)/compat-wireless
KERNEL_DIR:=$(BASE_RELEASE_DIR)/workspace/kernel/android-2.6.35
ANDROID_DIR:=$(BASE_RELEASE_DIR)/workspace/mydroid
ROOTFS_DIR:=$(BASE_RELEASE_DIR)/output/sd/rootfs

# source definitions
WL12xx_DIR?=

# additional packages
FIRMWARE_DIR?=$(ROOTFS_DIR)/system/etc/firmware/ti-connectivity
NVS_DIR?=$(ROOTFS_DIR)/system/etc/firmware/ti-connectivity
ADDITIONAL_BIN_DIR?=$(ROOTFS_DIR)/system/bin
SUPPLICANT_DIR?=$(ROOTFS_DIR)/system/bin
HOSTAPD_DIR?=$(ROOTFS_DIR)/system/bin
CALIBRATOR_DIR?=$(ROOTFS_DIR)/system/bin
IW_DIR?=$(ROOTFS_DIR)/system/bin

# compat/build definitions (exported)
ARCH:=arm
CROSS_COMPILE:=arm-none-linux-gnueabi-
GIT_TREE:=$(WL12xx_DIR)
GIT_COMPAT_TREE:=$(COMPAT_DIR)
export ARCH
export CROSS_COMPILE
export GIT_TREE
export GIT_COMPAT_TREE

# rules
.PHONY: test all install compat-update

test:
	# test cross-tools
	$(CROSS_COMPILE)gcc --version
ifeq ($(WL12xx_DIR),) 
	$(error wl12xx directory is not defined, please pass it's path using WL12xx_DIR argument)
endif
	@if [ ! -d $(WL12xx_DIR) ] ; then echo "wl12xx directory does not exist ($(WL12xx_DIR))" ; fi
	@echo "test ok"

install: all
	@echo CREATING wl12xx PACKAGE
	@if [ -d $(TRASH_DIR) ] ; then rm -rf $(TRASH_DIR) ; fi
	@mkdir $(TRASH_DIR)
	@find $(COMAPT_WIRELESS_DIR) -name *.ko -exec cp {} $(TRASH_DIR) \;
	@cp $(FIRMWARE_DIR)/wl12*-fw*.bin* $(TRASH_DIR)
	@cp $(NVS_DIR)/*nvs* $(TRASH_DIR)
	@cp $(SUPPLICANT_DIR)/wpa_supplicant $(TRASH_DIR)
	@cp $(SUPPLICANT_DIR)/wpa_cli $(TRASH_DIR)
	@cp $(HOSTAPD_DIR)/hostapd_bin $(TRASH_DIR)
	@cp $(HOSTAPD_DIR)/hostapd_cli $(TRASH_DIR)
	@cp $(CALIBRATOR_DIR)/calibrator $(TRASH_DIR)
	@cp $(IW_DIR)/iw $(TRASH_DIR)
	@cp -r $(SCRIPTS_DIR)/* $(TRASH_DIR)
	@echo packing...
	@cd $(TRASH_DIR) ; tar cvjf $(PWD)/wl12xx_binaries.tar.bz2 *
	@rm -rf $(TRASH_DIR)
	@echo wl12xx PACKAGE IS READY 

all: compat-update
	# test cross-tools
	$(CROSS_COMPILE)gcc --version
	# prepare compat-wireless
	cd $(COMAPT_WIRELESS_DIR) ; sh scripts/admin-refresh.sh ; scripts/driver-select wl12xx
	# make compat-wireless
	@$(MAKE) -C $(COMAPT_WIRELESS_DIR) KLIB=$(KERNEL_DIR) KLIB_BUILD=$(KERNEL_DIR)
	@echo DRIVER BUILD DONE.
	
compat-update: $(COMPAT_DIR) $(COMAPT_WIRELESS_DIR)
	cd $(COMPAT_DIR) ; git fetch origin ; git rebase origin
	cd $(COMAPT_WIRELESS_DIR) ; sh scripts/admin-clean.sh
	cd $(COMAPT_WIRELESS_DIR) ; git reset --hard ; git fetch origin ; git rebase origin
	
$(COMPAT_DIR): $(BUILD_DIR)
	git clone $(COMPAT_BASE_DIR) $(COMPAT_DIR)
	
$(COMAPT_WIRELESS_DIR): $(BUILD_DIR)
	git clone $(COMAPT_WIRELESS_BASE_DIR) $(COMAPT_WIRELESS_DIR)
	
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
