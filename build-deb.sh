#!/usr/bin/env bash
# install dep
echo "deb-src [trusted=true] https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | tee /etc/apt/sources.list.d/deepin-sources.list
apt update
apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git vim libelf-dev sudo
apt install -y gcc-loongarch64-linux-gnu g++-loongarch64-linux-gnu binutils-loongarch64-linux-gnu \
    cpp-loongarch64-linux-gnu
apt build-dep -y linux

git clone https://github.com/deepin-community/kernel --depth=1 -b linux-6.12.y

cd kernel
# 删除 .git 目录以避免版本号带 commit
rm -rf .git

/usr/bin/loongarch64-linux-gnu-gcc --version

make ARCH=loongarch CROSS_COMPILE=loongarch64-linux-gnu- deepin_loongarch_desktop_defconfig

scripts/config --undefine CONFIG_DEBUG_INFO
scripts/config --undefine CONFIG_DEBUG_INFO_DWARF5
scripts/config --undefine CONFIG_DEBUG_INFO_COMPRESSED_NONE 
scripts/config --undefine CONFIG_PAHOLE_HAS_SPLIT_BTF
scripts/config --undefine CONFIG_PAHOLE_HAS_LANG_EXCLUDE
scripts/config --undefine CONFIG_GDB_SCRIPTS

scripts/config --set-val CONFIG_DEBUG_INFO_NONE y

scripts/config --undefine CONFIG_HAVE_PAGE_SIZE_16KB
scripts/config --undefine CONFIG_PAGE_SIZE_16KB
scripts/config --undefine CONFIG_16KB_3LEVEL

scripts/config --set-val CONFIG_PAGE_SHIFT 12
scripts/config --set-val CONFIG_HAVE_PAGE_SIZE_4KB y
scripts/config --set-val CONFIG_PAGE_SIZE_4KB y
scripts/config --set-val CONFIG_4KB_3LEVEL y


scripts/config --set-str CONFIG_LOCALVERSION "-loong64-4k-pagesize-gxde-desktop"

# build deb packages
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make DPKG_FLAGS=-d ARCH=loongarch CROSS_COMPILE=loongarch64-linux-gnu- bindeb-pkg -j"$CPU_CORES"

cd ..
rm -rf linux-libc-dev*.deb *dbg*.deb
mv *.deb ..