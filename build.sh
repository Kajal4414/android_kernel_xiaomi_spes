#!/bin/bash

# Color Variables
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Install Dependencies
# sudo apt install -y elfutils libarchive-tools flex bc cpio && sudo apt remove -y libyaml-dev

# Clone Clang
[ ! -d "clang-r450784e" ] && git clone --depth 1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git clang-r450784e

# Set Environment Variables
export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build
export PATH="$(pwd)/clang-r450784e/bin:$PATH"

# Cleanup
rm -rf KernelSU AnyKernel3 BloodMoon*.zip build.log out

# Integrate KernelSU
if [ -e "drivers/kernelsu" ] || grep -q 'CONFIG_LOCALVERSION="-BloodMoon-KernelSU"' arch/arm64/configs/vendor/spes-perf_defconfig; then
	curl -LSs "https://raw.githubusercontent.com/Kajal4414/KernelSU/main/kernel/setup.sh" | bash -
	echo -e "${GREEN}\nBuilding with KernelSU.${NC}"
	ZIP_SUFFIX="SU"
else
	echo -e "${YELLOW}Building without KernelSU.${NC}"
	ZIP_SUFFIX=""
fi

# Build Kernel
make O=out ARCH=arm64 vendor/spes-perf_defconfig LLVM=1 LLVM_IAS=1 Image.gz dtb.img dtbo.img -j$(nproc --all) 2> >(tee build.log >&2) || exit $?

# Package Kernel
if [ -f "out/arch/arm64/boot/Image.gz" ]; then
	ZIPNAME="BloodMoon_Kernel${ZIP_SUFFIX}_$(date '+%d-%m-%Y')_$(git rev-parse --short=7 HEAD).zip"
	git clone -q https://github.com/Kajal4414/AnyKernel3.git AnyKernel3
	cp out/arch/arm64/boot/{Image.gz,dtbo.img} AnyKernel3
	(cd AnyKernel3 && zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder)
	[ -f "$ZIPNAME" ] && echo -e "\n${GREEN}Kernel build completed in $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds!${NC}"
else
	echo -e "${RED}\nKernel build failed, Image.gz not found!${NC}"
fi
