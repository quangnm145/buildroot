# Phan tich Buildroot Rockchip SDK va huong dan bring-up Radxa ROCK 4D tren `buidroot-base`

Tai lieu nay so sanh cach Rockchip SDK build kernel/rootfs voi Buildroot upstream trong `~/workdir/buidroot-base`, sau do dua ra huong bring-up kernel va rootfs cho Radxa ROCK 4D (RK3576).

## 1. Tong quan hai cay source

### Rockchip SDK: `~/workdir/buildroot`

Rockchip SDK khong chi la mot cay Buildroot. No la mot SDK gom nhieu lop:

- `build.sh`: wrapper chinh, doc `output/.config`, goi cac script trong `device/rockchip/common/scripts/`.
- `device/rockchip/.chips/rk3576/`: board/chip defconfig cua SDK, partition table, FIT ITS.
- `kernel-6.1/`: kernel vendor Rockchip.
- `u-boot/`: U-Boot vendor Rockchip.
- `rkbin/`: binary blob/DDR/trust/loader cua Rockchip.
- `buildroot/`: Buildroot da duoc Rockchip patch, them package va config include rieng.
- `output/`: noi luu cau hinh SDK va firmware/image da sinh.

Voi ROCK 4D, SDK dang dung:

```text
RK_DEFCONFIG="rockchip_rk3576_rock_4d_defconfig"
RK_CHIP_FAMILY="rk3576"
RK_BUILDROOT_CFG="rockchip_rk3576"
RK_ROOTFS_SYSTEM="buildroot"
RK_ROOTFS_TYPE="ext4"
RK_UBOOT_CFG="rk3576"
RK_UBOOT_SPL=y
RK_KERNEL_CFG="rockchip_linux_defconfig"
RK_KERNEL_DTS_NAME="rk3576-rock-4d"
RK_USE_FIT_IMG=y
RK_WIFIBT_CHIP="AIC8800D80-USB"
```

File board SDK cho ROCK 4D rat ngan:

```text
RK_UBOOT_SPL=y
RK_WIFIBT_CHIP="AIC8800D80-USB"
RK_KERNEL_DTS_NAME="rk3576-rock-4d"
RK_USE_FIT_IMG=y
```

Nghia la ROCK 4D thua huong hau het cau hinh tu chip RK3576 va cac default cua SDK, chi override DTS, Wi-Fi/BT, SPL va kieu boot image FIT.

### Buildroot base: `~/workdir/buidroot-base`

Day la Buildroot gan upstream hon. Moi board thuong duoc gom vao mot defconfig duy nhat:

- `configs/<board>_defconfig`
- `board/<vendor>/<board>/genimage.cfg`
- `board/<vendor>/<board>/post-build.sh`
- `board/<vendor>/<board>/extlinux.conf`
- optional: kernel/U-Boot fragments, patch dir, rootfs overlay.

Repo base hien co Radxa ROCK 4SE va ROCK 5B:

```text
board/radxa/rock4se/
board/radxa/rock5b/
configs/rock4se_defconfig
configs/rock5b_defconfig
```

Nhung chua co `rk3576`/`rock-4d` trong cau hinh kernel/U-Boot cua base. Vi vay bring-up ROCK 4D tren base khong the chi copy mot defconfig la xong; giai doan dau nen dung kernel va U-Boot vendor tu SDK.

## 2. Rockchip SDK build kernel nhu the nao

Script chinh: `device/rockchip/common/scripts/mk-kernel.sh`.

Luong build:

1. `build.sh` doc `output/.config`.
2. Xac dinh:
   - `RK_KERNEL_ARCH=arm64`
   - `RK_KERNEL_CFG=rockchip_linux_defconfig`
   - `RK_KERNEL_DTS_NAME=rk3576-rock-4d`
   - `RK_KERNEL_IMG=kernel/arch/arm64/boot/Image`
   - `RK_BOOT_FIT_ITS=device/rockchip/.chips/rk3576/boot.its`
3. Tao kernel config bang:
   - defconfig goc: `rockchip_linux_defconfig`
   - fragment theo chip neu co: `rk3576.config`, `rk3576_linux.config`
   - fragment extra tu `RK_KERNEL_CFG_FRAGMENTS`
4. Build target:
   ```bash
   make <RK_KERNEL_DTS_NAME>.img
   ```
   Voi ROCK 4D la:
   ```bash
   make rk3576-rock-4d.img
   ```
5. Neu `RK_USE_FIT_IMG=y`, script dong goi `Image`, `rk3576-rock-4d.dtb`, `resource.img` thanh `boot.img` bang `boot.its`.
6. Link ket qua sang firmware dir:
   ```text
   output/firmware/boot.img
   ```

Diem can nho: Rockchip build kernel khong chi tao `Image` va `.dtb`; no tao Android-style/FIT `boot.img`.

## 3. Rockchip SDK build rootfs nhu the nao

Script chinh:

- `device/rockchip/common/scripts/mk-rootfs.sh`
- `device/rockchip/common/scripts/mk-buildroot.sh`
- `buildroot/board/rockchip/common/post-build.sh`

Luong build Buildroot rootfs:

1. SDK chon `RK_BUILDROOT_CFG=rockchip_rk3576`.
2. `mk-buildroot.sh` goi:
   ```bash
   make -C buildroot O=buildroot/output/rockchip_rk3576 rockchip_rk3576_defconfig
   utils/brmake -C buildroot O=buildroot/output/rockchip_rk3576
   ```
3. `rockchip_rk3576_defconfig` khong phai defconfig phang. No include nhieu fragment:
   ```text
   base/base.config
   chips/rk3576_aarch64.config
   gpu/gpu.config
   multimedia/audio.config
   multimedia/camera.config
   multimedia/mpp.config
   wifibt/bt.config
   wifibt/wireless.config
   npu2.config
   gui/weston.config
   ...
   ```
4. Chip config them overlay:
   ```text
   BR2_ROOTFS_OVERLAY+="board/rockchip/rk3576/fs-overlay/"
   ```
5. Post-build cua Rockchip copy overlay theo profile, chay cac post hook: hostname, locale, ldconfig, udev rules, Wi-Fi/BT, USB gadget/adbd, module handling, log guardian, fstab/partition helper.
6. Image rootfs mac dinh la `rootfs.ext4`.

Diem can nho: rootfs cua Rockchip SDK rat giau package vendor: Mali, MPP, RGA, RKAIQ/camera, rknpu2, rkwifibt, Weston, Chromium, test tools, USB gadget, recovery/update. Buildroot base chi co mot phan rat nho nhu `rockchip-rkbin` va `rockchip-mali`.

## 4. Khac nhau chinh voi `buidroot-base`

| Hang muc | Rockchip SDK | Buildroot base |
|---|---|---|
| Entry point | `./build.sh`, `make` wrapper cua SDK | `make <board>_defconfig && make` |
| Cau hinh board | `device/rockchip/.chips/<chip>/<board>_defconfig` | `configs/<board>_defconfig` |
| Rootfs config | `buildroot/configs/rockchip_*.defconfig` co `#include` fragment | defconfig phang, upstream-style |
| Kernel | vendor `kernel-6.1`, target `<dts>.img`, FIT/boot.img | Buildroot package `linux`, thuong tao `Image`, `.dtb`, install vao `/boot` |
| Bootloader | vendor `u-boot/make.sh`, `rkbin`, SPL/MiniLoader, `uboot.img/trust.img` | Buildroot package `uboot`, tao `idbloader.img`, `u-boot.itb` hoac `u-boot-rockchip.bin` tuy board |
| Partition | Rockchip `parameter.txt`, GPT Android-style: uboot/misc/boot/recovery/rootfs/oem/userdata | `genimage.cfg`, thuong sdcard image don gian |
| Boot flow | Loader -> `boot.img` FIT -> rootfs partition | U-Boot/extlinux -> `/boot/Image` + `.dtb` -> rootfs |
| Rootfs post process | Nhieu hook Rockchip ngoai Buildroot | `post-build.sh` gon, board-specific |
| Vendor multimedia | Co MPP/RGA/RKAIQ/NPU/camera/GStreamer Rockchip | Khong co san, can port package neu can |
| ROCK 4D/RK3576 support | Co DTS/kernel/U-Boot vendor | Chua co san trong base hien tai |

## 5. Muc tieu bring-up ROCK 4D tren `buidroot-base`

Nen chia lam 2 pha.

### Pha A: boot toi thieu

Muc tieu:

- UART log len duoc.
- U-Boot load duoc kernel.
- Kernel boot voi `rk3576-rock-4d.dtb`.
- Mount rootfs Buildroot base tu SD/eMMC.
- Co shell login.

Chua can:

- GPU/Wayland.
- Camera/RKAIQ.
- MPP/RGA/NPU.
- Wi-Fi AIC8800D80.
- recovery/update image Rockchip.

### Pha B: them tinh nang vendor

Sau khi boot toi thieu on dinh moi port:

- firmware/module Wi-Fi `AIC8800D80-USB`
- GPU/Mali
- MPP/RGA/GStreamer Rockchip
- camera/RKAIQ
- RKNPU2
- USB gadget/adbd neu can
- partition `oem`, `userdata`, recovery/update neu can quy trinh san pham.

## 6. Cach tao board ROCK 4D trong `buidroot-base`

### 6.1. Tao layout board

Nen tao thu muc:

```text
board/radxa/rock4d/
├── extlinux.conf
├── genimage.cfg
├── linux.fragment
├── post-build.sh
├── readme.txt
└── patches/
```

Co the lay form tu `board/radxa/rock4se` hoac `board/radxa/rock5b`.

### 6.2. Defconfig toi thieu de bat dau

Tao `configs/rock4d_defconfig` theo huong:

```text
BR2_aarch64=y
BR2_cortex_a72_a53=y
BR2_TARGET_GENERIC_HOSTNAME="rock-4d"
BR2_TARGET_GENERIC_ISSUE="Welcome to Buildroot for Radxa ROCK 4D"
BR2_ROOTFS_DEVICE_CREATION_DYNAMIC_MDEV=y
BR2_SYSTEM_DHCP="eth0"

BR2_ROOTFS_POST_BUILD_SCRIPT="board/radxa/rock4d/post-build.sh"
BR2_ROOTFS_POST_IMAGE_SCRIPT="support/scripts/genimage.sh"
BR2_ROOTFS_POST_SCRIPT_ARGS="-c board/radxa/rock4d/genimage.cfg"

BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_TARBALL=y
BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION="file:///home/quangnm/workdir/buildroot/kernel-6.1.tar.gz"
BR2_LINUX_KERNEL_USE_DEFCONFIG=y
BR2_LINUX_KERNEL_DEFCONFIG="rockchip_linux"
BR2_LINUX_KERNEL_DTS_SUPPORT=y
BR2_LINUX_KERNEL_INTREE_DTS_NAME="rockchip/rk3576-rock-4d"
BR2_LINUX_KERNEL_INSTALL_TARGET=y
BR2_LINUX_KERNEL_NEEDS_HOST_OPENSSL=y
BR2_LINUX_KERNEL_NEEDS_HOST_PYTHON3=y

BR2_TARGET_ROOTFS_EXT2=y
BR2_TARGET_ROOTFS_EXT2_4=y
BR2_TARGET_ROOTFS_EXT2_SIZE="512M"

BR2_PACKAGE_HOST_DOSFSTOOLS=y
BR2_PACKAGE_HOST_DTC=y
BR2_PACKAGE_HOST_GENIMAGE=y
BR2_PACKAGE_HOST_MTOOLS=y
```

Ghi chu:

- Buildroot khong build truc tiep tu working tree local kernel bang option defconfig thong thuong; cach don gian la tao tarball vendor kernel va tro `BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION` vao `file://...`.
- Neu muon phat trien kernel nhanh, dung `local.mk`/override source cua Buildroot thay vi nen tarball lai moi lan.
- `BR2_cortex_a72_a53=y` la theo SDK `rk3576.config`. Neu toolchain/base co option CPU chinh xac hon cho RK3576 thi cap nhat sau.

### 6.3. Tao tarball kernel vendor

Tu SDK:

```bash
cd ~/workdir/buildroot
tar --exclude='.git' --exclude='*.o' --exclude='*.cmd' \
    --exclude='*.dtb' --exclude='*.tmp' \
    -czf /tmp/kernel-6.1-rk3576-rock4d.tar.gz kernel-6.1
cp /tmp/kernel-6.1-rk3576-rock4d.tar.gz ~/workdir/buildroot/kernel-6.1.tar.gz
```

Sau do cap nhat defconfig:

```text
BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION="file:///home/quangnm/workdir/buildroot/kernel-6.1.tar.gz"
```

Neu Buildroot extract ra thu muc co ten `kernel-6.1`, package linux van build duoc; neu gap loi strip component, nen tao tarball sao cho noi dung source nam o top-level cua archive.

### 6.4. `post-build.sh`

File toi thieu:

```sh
#!/bin/sh

BOARD_DIR="$(dirname "$0")"

install -m 0644 -D "$BOARD_DIR/extlinux.conf" \
	"$TARGET_DIR/boot/extlinux/extlinux.conf"
```

Nho chmod:

```bash
chmod +x board/radxa/rock4d/post-build.sh
```

### 6.5. `extlinux.conf`

Neu dung U-Boot/extlinux thay vi Rockchip `boot.img`, file toi thieu:

```text
label Radxa ROCK 4D Linux
  kernel /boot/Image
  devicetree /boot/rk3576-rock-4d.dtb
  append root=/dev/mmcblk1p1 rw rootfstype=ext4 earlycon rootwait console=ttyS2,1500000n8
```

Can xac nhan UART console cua ROCK 4D trong log vendor. Rockchip/Radxa hay dung baudrate `1500000`, nhung tty co the la `ttyS2`, `ttyFIQ0` hoac console alias tu DTS.

### 6.6. `genimage.cfg`

Cho pha boot toi thieu qua extlinux, co the bat dau giong ROCK 4SE:

```text
image sdcard.img {
	hdimage {
	}

	partition u-boot-tpl-spl-dtb {
		in-partition-table = "no"
		image = "idbloader.img"
		offset = 32K
	}

	partition u-boot-dtb {
		in-partition-table = "no"
		image = "u-boot.itb"
		offset = 8M
		size = 30M
	}

	partition rootfs {
		partition-type = 0x83
		image = "rootfs.ext4"
	}
}
```

Nhung voi RK3576, `idbloader.img` va `u-boot.itb` chua chac Buildroot base tu tao duoc. Giai doan dau co the copy tu SDK vendor build sang `output/images/` bang post-image hoac lam thu cong de validate rootfs.

## 7. U-Boot/loader cho RK3576

`buidroot-base` hien chua co support RK3576/U-Boot board ROCK 4D. Co 3 huong:

### Huong khuyen nghi cho bring-up nhanh

Dung U-Boot/loader vendor SDK truoc:

```bash
cd ~/workdir/buildroot
./build.sh rockchip_rk3576_rock_4d_defconfig
./build.sh loader
```

Lay cac file loader/boot tu `output/firmware/` hoac `u-boot/` tuy SDK sinh ra:

```text
MiniLoaderAll.bin
uboot.img
trust.img
boot.img
```

Sau do flash theo partition Rockchip SDK, hoac dung loader vendor de boot rootfs ext4 do `buidroot-base` tao.

### Huong tich hop vao Buildroot base

Can port U-Boot vendor RK3576 vao Buildroot package `uboot`:

- dung custom git/tarball cua vendor U-Boot;
- `BR2_TARGET_UBOOT_BOARD_DEFCONFIG="rk3576"`;
- them make options neu can tu `u-boot/make.sh`;
- dam bao sinh duoc `idbloader.img`/`u-boot.itb` hoac format tuong duong;
- neu can binary DDR/trust, cap nhat `package/rockchip-rkbin` de co file RK3576 tu `rkbin`.

### Huong upstream lau dai

Khi U-Boot upstream ho tro RK3576/ROCK 4D tot, chuyen defconfig ve custom version upstream va bo dan vendor scripts.

## 8. Rootfs base toi thieu

Lenh build:

```bash
cd ~/workdir/buidroot-base
make rock4d_defconfig
make
```

Ket qua mong doi:

```text
output/images/Image
output/images/rk3576-rock-4d.dtb
output/images/rootfs.ext4
output/images/rootfs.tar
output/images/sdcard.img
```

Neu chua tich hop U-Boot RK3576 vao base, `sdcard.img` co the thieu loader. Khi do dung rootfs/kernel cua base ket hop loader/boot flow vendor SDK de test.

## 9. Cach ket hop vendor boot voi rootfs base

Day la cach thuc dung de bring-up nhanh:

1. Build loader/kernel vendor tu SDK de co boot chain chac chan ho tro RK3576/ROCK 4D.
2. Build rootfs ext4 tu `buidroot-base`.
3. Ghi rootfs base vao partition `rootfs` trong layout Rockchip SDK.
4. Giu `boot.img` vendor neu kernel base chua boot; sau do doi dan sang kernel build boi base.
5. Khi kernel base boot on, chuyen boot flow sang extlinux/genimage trong base.

Neu dung partition Rockchip SDK, `parameter.txt` cho RK3576 co layout:

```text
uboot, misc, boot, recovery, backup, rootfs, oem, userdata
```

`rootfs` bat dau tai offset `0x00078000` sector trong file parameter cua SDK. Nen dung tool flash cua Rockchip/SDK thay vi tu tinh offset bang tay khi co the.

## 10. Cac diem can port sau khi shell len

### Wi-Fi/BT AIC8800D80-USB

SDK khai bao:

```text
RK_WIFIBT_CHIP="AIC8800D80-USB"
```

Can port:

- kernel module/firmware AIC8800D80;
- init script load module;
- firmware vao `/lib/firmware`;
- package `wpa_supplicant`, `bluez` neu can.

### GPU/Weston

Base co `package/rockchip-mali`, nhung can check dung GPU/lib cho RK3576. SDK dung profile `gpu/gpu.config` va `gui/weston.config`.

### VPU/RGA/GStreamer

SDK co package:

```text
rockchip-mpp
rockchip-rga
gstreamer1-rockchip
libv4l-rkmpp
```

Base hien chua co cac package nay. Neu can multimedia, port package tu `~/workdir/buildroot/buildroot/package/rockchip/`.

### Camera/RKAIQ

Can port:

```text
camera-engine-rkaiq
rkadk
rkipc/rkaiq related overlay neu dung IPC stack
```

Khong nen port ngay o pha A vi phu thuoc kernel driver, media graph, sensor DTS va firmware.

### NPU

SDK dung:

```text
npu2.config
rknpu2
rknpu-fw
```

Chi port sau khi kernel va rootfs on dinh.

## 11. Checklist bring-up thuc te

1. Xac nhan SDK vendor boot duoc ROCK 4D:
   ```bash
   cd ~/workdir/buildroot
   ./build.sh rockchip_rk3576_rock_4d_defconfig
   ./build.sh loader
   ./build.sh kernel
   ./build.sh buildroot
   ```
2. Luu lai UART log vendor: U-Boot version, kernel command line, console tty, mmc index cua rootfs.
3. Tao `board/radxa/rock4d` va `configs/rock4d_defconfig` trong `buidroot-base`.
4. Build rootfs base toi thieu.
5. Boot bang loader/kernel vendor + rootfs base.
6. Neu rootfs mount fail, sua:
   - `root=/dev/mmcblkXpY`
   - `rootfstype=ext4`
   - partition table/genimage
   - kernel driver MMC/storage built-in.
7. Khi vao shell, check:
   ```bash
   uname -a
   cat /proc/cmdline
   mount
   dmesg | grep -Ei "mmc|ext4|firmware|fail|error"
   ip link
   ```
8. Chuyen kernel sang Buildroot base build tu vendor tarball.
9. Chuyen U-Boot sang Buildroot base neu can image doc lap.
10. Port lan luot Wi-Fi, GPU, multimedia, camera, NPU.

## 12. Ket luan

Khac biet cot loi la Rockchip SDK co mot lop orchestration rieng nam ngoai Buildroot. Kernel duoc build thanh `boot.img` FIT theo DTS `rk3576-rock-4d`; rootfs Buildroot duoc ghep tu nhieu config fragment va post hook vendor. `buidroot-base` sach hon, de bao tri hon, nhung hien chua co RK3576/ROCK 4D support san.

Vi vay chien luoc bring-up an toan la:

1. Dung vendor SDK de xac nhan boot chain va lay kernel/U-Boot/DTS chuan cho ROCK 4D.
2. Tao board `rock4d` trong `buidroot-base` de build rootfs toi thieu.
3. Boot rootfs base bang vendor boot chain.
4. Dua kernel vendor vao Buildroot base bang custom tarball/source override.
5. Port U-Boot va package vendor chi khi can.
