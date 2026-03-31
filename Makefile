# =============================================
# QNM Raspberry Pi 4B br2-external Makefile
# =============================================

BR2_EXTERNAL := $(CURDIR)
UBOOT_SRC := $(BR2_EXTERNAL)/../uboot

# Target mặc định
all:
	$(MAKE) -C ../buildroot BR2_EXTERNAL=$(BR2_EXTERNAL) UBOOT_OVERRIDE_SRCDIR=$(UBOOT_SRC) LINUX_OVERRIDE_SRCDIR=$(UBOOT_SRC)/../linux-rpi

%:
	$(MAKE) -C ../buildroot BR2_EXTERNAL=$(BR2_EXTERNAL) UBOOT_OVERRIDE_SRCDIR=$(UBOOT_SRC) LINUX_OVERRIDE_SRCDIR=$(UBOOT_SRC)/../linux-rpi $@
