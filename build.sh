#!/bin/bash

# Color Variables
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Install Dependencies
# sudo apt update && sudo apt install -y elfutils libarchive-tools flex bc cpio && sudo apt remove -y libyaml-0-2

# Clone Clang
[ ! -d "clang-r450784e" ] && git clone --depth 1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git clang-r450784e

# Set Environment Variables
export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build
export PATH="$(pwd)/clang-r450784e/bin:$PATH"

# Cleanup
rm -rf KernelSU AnyKernel3 Uvite*.zip build.log out

# Integrate KernelSU
read -t 8 -p $'\033[1;33m\nDo you want to integrate KernelSU? (y/N):\033[0m ' integrate_kernelsu || integrate_kernelsu="N"
if [ "$integrate_kernelsu" = "y" ]; then
	[ ! -e "drivers/kernelsu" ] && git fetch -q https://github.com/Kajal4414/kernel_xiaomi_sm6225.git uvite-dev && git cherry-pick a172dcd >/dev/null 2>&1 && echo -e "${GREEN}KernelSU integration patch applied! Rerun the script!${NC}" && exit 1
	curl -LSs "https://raw.githubusercontent.com/Kajal4414/KernelSU/main/kernel/setup.sh" | bash -
	echo -e "${GREEN}\nBuilding with KernelSU.${NC}"
	ZIP_SUFFIX="SU"
else
	echo -e "${YELLOW}Building without KernelSU.${NC}"
	ZIP_SUFFIX=""
fi

# Build Kernel
make O=out ARCH=arm64 vendor/spes-perf_defconfig LLVM=1 LLVM_IAS=1 Image.gz dtbo.img -j$(nproc --all) 2> >(tee build.log >&2) || exit $?

# Package Kernel
if [ -f "out/arch/arm64/boot/Image.gz" ]; then
	ZIPNAME="Uvite_Kernel${ZIP_SUFFIX}_$(date '+%d-%m-%Y')_$(git rev-parse --short=7 HEAD).zip"
	git clone -q https://github.com/Kajal4414/AnyKernel3.git AnyKernel3
	cp out/arch/arm64/boot/{Image.gz,dtbo.img} AnyKernel3
	(cd AnyKernel3 && zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder)
	[ -f "$ZIPNAME" ] && echo -e "\n${GREEN}Kernel build completed in $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds!${NC}"
else
	echo -e "${RED}\nKernel build failed, Image.gz not found!${NC}"
fi
