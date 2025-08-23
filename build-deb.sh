#!/usr/bin/env bash
# install dep
apt install deepin-keyring -y
echo "deb [trusted=true] https://community-packages.deepin.com/deepin/beige/ crimson main community commercial" | tee /etc/apt/sources.list.d/deepin-sources.list
echo "deb-src [trusted=true] https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | tee /etc/apt/sources.list.d/deepin-sources.list
dpkg --add-architecture loong64
apt update
apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git vim libelf-dev sudo zstd
apt build-dep -y linux
apt install -y gcc-loongarch64-linux-gnu g++-loongarch64-linux-gnu binutils-loongarch64-linux-gnu \
    cpp-loongarch64-linux-gnu
apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu \
    cpp-aarch64-linux-gnu
apt install -y gcc-mips64el-linux-gnuabi64 g++-mips64el-linux-gnuabi64 binutils-mips64el-linux-gnuabi64 \
    cpp-mips64el-linux-gnuabi64
apt install -y gcc-riscv64-linux-gnu g++-riscv64-linux-gnu binutils-riscv64-linux-gnu \
    cpp-riscv64-linux-gnu

git clone https://gitee.com/phytium_embedded/phytium-linux-kernel --depth=1 -b linux-6.6

cd phytium-linux-kernel

# 检测 build-version 脚本是否存在
if [[ ! -f init/build-version ]]; then
    cp ../build-version init -rv
    chmod +x init/build-version
fi

# 删除 .git 目录以避免版本号带 commit
rm -rf .git


if [[ $GXDE_CROSS_ARCH == "arm64" ]]; then
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- phytium_defconfig
else
    exit 1
fi
scripts/config --set-str CONFIG_LOCALVERSION "-phytium-embedded-gxde"


scripts/config --undefine CONFIG_DEBUG_INFO
scripts/config --undefine CONFIG_DEBUG_INFO_DWARF5
scripts/config --undefine CONFIG_DEBUG_INFO_COMPRESSED_NONE 
scripts/config --undefine CONFIG_PAHOLE_HAS_SPLIT_BTF
scripts/config --undefine CONFIG_PAHOLE_HAS_LANG_EXCLUDE
scripts/config --undefine CONFIG_GDB_SCRIPTS

scripts/config --set-val CONFIG_DEBUG_INFO_NONE y

scripts/config --undefine CONFIG_SYSTEM_TRUSTED_KEYRING
scripts/config --undefine CONFIG_SYSTEM_TRUSTED_KEYS
scripts/config --undefine CONFIG_MODULE_SIG_KEY
scripts/config --undefine CONFIG_MODULE_SIG_KEY_TYPE_RSA


# build deb packages
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make DPKG_FLAGS=-d ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bindeb-pkg -j"$CPU_CORES"

cd ..
rm -rf linux-libc-dev*.deb *dbg*.deb
mv *.deb ..
