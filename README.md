# GXDE Kernel Builder

用于构建 GXDE OS 内核的自动化构建工具，基于 GitHub Actions 与交叉编译链实现多架构交叉编译。

## 支持的架构

| 架构 | 说明 |
|------|------|
| `amd64` | x86 64位 |
| `i386` | x86 32位 |
| `arm64` | ARM 64位 (aarch64) |
| `mips64el` | 龙芯3A (MIPS64) |
| `loong64` | 龙架构 (LoongArch) |
| `riscv64` | RISC-V 64位 |

## 构建方式

本项目通过 GitHub Actions 进行自动化构建。

### 触发构建

1. **推送 Tag 触发** - 推送任意 tag 即可自动触发构建
2. **手动触发** - 在 GitHub Actions 页面手动运行工作流
   - `program-builder.yml` - 标准构建
   - `program-builder-tianlu.yml` - 天路构建

## 技术细节

### 交叉编译工具链

本项目使用交叉编译技术，在 x86 主机上构建其他架构的内核：

| 目标架构 | 编译器 | 链接器 |
|----------|--------|--------|
| `i386` | `i686-linux-gnu-gcc` | `i686-linux-gnu-ld` |
| `arm64` | `aarch64-linux-gnu-gcc` | `aarch64-linux-gnu-ld` |
| `mips64el` | `mips64el-linux-gnuabi64-gcc` | `mips64el-linux-gnuabi64-ld` |
| `loong64` | `loongarch64-linux-gnu-gcc` | `loongarch64-linux-gnu-ld` |
| `riscv64` | `riscv64-linux-gnu-gcc` | `riscv64-linux-gnu-ld` |

### 内核配置

各架构使用对应的 defconfig：

| 架构 | 配置文件 |
|------|----------|
| `amd64` | `deepin_x86_desktop_defconfig` |
| `i386` | `gxde_i386_desktop_defconfig` |
| `arm64` | `deepin_arm64_desktop_defconfig` |
| `mips64el` | `deepin_loongson3_desktop_defconfig` |
| `loong64` | `deepin_loongarch_desktop_defconfig` |
| `riscv64` | `deepin_riscv64_desktop_defconfig` |

### 内核版本标识

构建的内核会添加版本后缀：`-{架构}-gxde-desktop`

例如：`6.6.142-arm64-gxde-desktop`

### 4K Pagesize 内核

对于 `loong64` 和 `mips64el` 架构，除标准内核外，还会额外构建 4K pagesize 版本：

- 版本后缀：`-{架构}-4k-pagesize-gxde-desktop`
- 适用于需要 4K 页大小的兼容场景

### 构建优化

为减小内核体积并加速构建，禁用了以下调试选项：

- `CONFIG_DEBUG_INFO` - 调试信息
- `CONFIG_SYSTEM_TRUSTED_KEYRING` - 系统信任密钥环
- `CONFIG_MODULE_SIG_KEY` - 模块签名密钥

### 构建依赖

主要构建依赖包括：

- 编译工具：`gcc`, `make`, `flex`, `bison`, `bc`
- 打包工具：`dpkg-dev`
- 其他工具：`libssl-dev`, `libelf-dev`, `zstd`

## 构建产物

构建完成后会生成以下 deb 包：

- `linux-image-*.deb` - 内核镜像包
- `linux-headers-*.deb` - 内核头文件包

## 内核源码

内核源码：https://github.com/GXDE-OS/kernel  
内核包虚包：https://gitee.com/GXDE-OS/linux-kernel-gxde

## 作者

gfdgd xi <3025613752@qq.com>