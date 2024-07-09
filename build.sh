#!/bin/bash

# Install Dependencies
sudo apt install -y elfutils libarchive-tools flex bc cpio

# Clone Clang
if [ ! -d "clang-r450784e" ]; then
	git clone --depth 1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git clang-r450784e
fi

# Set Environment Variables
export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build
export PATH="$(pwd)/clang-r450784e/bin:$PATH"

# Cleanup
rm -rf out build.log KernelSU AnyKernel3 *.zip

# Integrate KernelSU
echo -e -n "\e[33mDo you want to integrate KernelSU? (y/N):\e[0m " && read integrate_kernelsu
if [ "$integrate_kernelsu" = "y" ]; then
	git fetch https://github.com/Kajal4414/kernel_xiaomi_sm6225.git uvite-dev
	git cherry-pick a172dcd
	curl -LSs "https://raw.githubusercontent.com/Kajal4414/KernelSU/main/kernel/setup.sh" | bash -
	ZIP_SUFFIX="SU"
else
	ZIP_SUFFIX=""
fi

# Build Kernel
make O=out ARCH=arm64 vendor/spes-perf_defconfig LLVM=1 LLVM_IAS=1 Image.gz dtbo.img -j$(nproc --all) 2> >(tee build.log >&2) || exit $?

# Package Kernel
if [ -f "out/arch/arm64/boot/Image.gz" ]; then
	ZIPNAME="Uvite_Kernel${ZIP_SUFFIX}_$(date '+%d-%m-%Y')_$(git rev-parse --short=7 HEAD).zip"
	git clone -q https://github.com/Kajal4414/AnyKernel3.git AnyKernel3
	cp "out/arch/arm64/boot/Image.gz" "out/arch/arm64/boot/dtbo.img" AnyKernel3
	(cd AnyKernel3 && zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder)
	if [ -f "$ZIPNAME" ]; then
		echo -e "\e[32m\nCompleted in $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds!\e[0m"
		echo -e "\e[32mZIP: $ZIPNAME\e[0m"
	fi
fi
