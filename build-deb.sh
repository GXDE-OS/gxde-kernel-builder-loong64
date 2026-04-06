#!/usr/bin/env bash
# install dep
chmod 1777 -Rv /tmp
apt install deepin-keyring -y
echo "deb [trusted=true] https://community-packages.deepin.com/deepin/beige/ crimson main community commercial" | tee /etc/apt/sources.list.d/deepin-sources.list
echo "deb-src [trusted=true] http://ftp.us.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | tee /etc/apt/sources.list.d/deepin-sources.list
dpkg --add-architecture loong64
dpkg --add-architecture $GXDE_CROSS_ARCH
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
apt install -y gcc-i686-linux-gnu g++-i686-linux-gnu binutils-i686-linux-gnu \
    cpp-i686-linux-gnu
# 安装对应架构的 libssl-dev 包，否则编译内核时会提示找不到 openssl/sha.h 头文件
apt install -y libssl-dev:$GXDE_CROSS_ARCH

git clone https://github.com/GXDE-OS/kernel --depth=1 -b linux-6.18.y 


cd kernel

# 检测 build-version 脚本是否存在
if [[ ! -f init/build-version ]]; then
    cp ../build-version init -rv
    chmod +x init/build-version
fi

# 删除 .git 目录以避免版本号带 commit
rm -rf .git

export DEBEMAIL="gfdgd xi <3025613752@qq.com>"

if [[ $GXDE_CROSS_ARCH == "i386" ]]; then
    make ARCH=arm64 CROSS_COMPILE=i686-linux-gnu- deepin_x86_desktop_defconfig
fi
if [[ $GXDE_CROSS_ARCH == "amd64" ]]; then
    make ARCH=x86 deepin_x86_desktop_defconfig
fi
if [[ $GXDE_CROSS_ARCH == "arm64" ]]; then
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- deepin_arm64_desktop_defconfig
fi
if [[ $GXDE_CROSS_ARCH == "mips64el" ]]; then
    exit 0
    #make ARCH=mips CROSS_COMPILE=mips64el-linux-gnuabi64- loongson3_defconfig
fi
if [[ $GXDE_CROSS_ARCH == "loong64" ]]; then
    make ARCH=loongarch CROSS_COMPILE=loongarch64-linux-gnu- deepin_loongarch_desktop_defconfig
fi
if [[ $GXDE_CROSS_ARCH == "riscv64" ]]; then
    make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- deepin_riscv64_desktop_defconfig
fi

scripts/config --set-str CONFIG_LOCALVERSION "-$GXDE_CROSS_ARCH-gxde-desktop"

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

if [[ $GXDE_CROSS_ARCH == "i386" ]]; then
    make ARCH=arm64 CROSS_COMPILE=i686-linux-gnu- DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
fi
if [[ $GXDE_CROSS_ARCH == "amd64" ]]; then
    make ARCH=x86 DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
fi
if [[ $GXDE_CROSS_ARCH == "arm64" ]]; then
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
fi
if [[ $GXDE_CROSS_ARCH == "mips64el" ]]; then
    make ARCH=mips CROSS_COMPILE=mips64el-linux-gnuabi64- DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
fi
if [[ $GXDE_CROSS_ARCH == "loong64" ]]; then
    make ARCH=loongarch CROSS_COMPILE=loongarch64-linux-gnu- DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
fi
if [[ $GXDE_CROSS_ARCH == "riscv64" ]]; then
    make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
fi

# 再重新编译个 4k pagesize 内核（mips, loongarch）
if [[ $GXDE_CROSS_ARCH == "loong64" ]] || [[ $GXDE_CROSS_ARCH == "mips64el" ]]; then
    scripts/config --set-str CONFIG_LOCALVERSION "-$GXDE_CROSS_ARCH-4k-pagesize-gxde-desktop"
    if [[ $GXDE_CROSS_ARCH == "loong64" ]]; then
        scripts/config --undefine CONFIG_HAVE_PAGE_SIZE_16KB
        scripts/config --undefine CONFIG_PAGE_SIZE_16KB
        scripts/config --undefine CONFIG_16KB_3LEVEL
        scripts/config --set-val CONFIG_PAGE_SHIFT 12
        scripts/config --set-val CONFIG_HAVE_PAGE_SIZE_4KB y
        scripts/config --set-val CONFIG_PAGE_SIZE_4KB y
        scripts/config --set-val CONFIG_4KB_3LEVEL y
        make ARCH=loongarch CROSS_COMPILE=loongarch64-linux-gnu- DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
    fi
    if [[ $GXDE_CROSS_ARCH == "mips64el" ]]; then
        scripts/config --set-val CONFIG_PAGE_SIZE_4KB y
        scripts/config --undefine CONFIG_PAGE_SIZE_16KB
        make ARCH=mips CROSS_COMPILE=mips64el-linux-gnuabi64- DPKG_FLAGS=-d bindeb-pkg -j"$CPU_CORES"
    fi
fi

cd ..
rm -rf linux-libc-dev*.deb *dbg*.deb
mv *.deb ..
