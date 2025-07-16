#!/usr/bin/env bash

set -e

KERNEL_DIR="$(pwd)"
CHAT_ID="-1001734041926"
DEVICE="garnet"
VERSION=BETA-KSU-SUSFS
DEFCONFIG="garnet_defconfig vendor/debugfs.config vendor/kernelsu.config"
IMAGE=${KERNEL_DIR}/out/arch/arm64/boot/Image.gz
ZIPNAME="S0NiX"
TANGGAL=$(date +"%H%M")
FINAL_ZIP="${ZIPNAME}-${VERSION}-${DEVICE}-${TANGGAL}.zip"
VERBOSE=0

# Telegram messaging function
telegram_push() {
  curl --progress-bar -F document=@"$1" https://api.telegram.org/bot$BOT_API/sendDocument \
	-F chat_id="$CHAT_ID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2"
}

# Get AnyKernel3
git clone https://github.com/ImSpiDy/AnyKernel3.git --depth=1 -b garnet

# Export Vars
KBUILD_BUILD_HOST="ArchLinux"
KBUILD_BUILD_USER="SpiDyNub"
KBUILD_COMPILER_STRING=$(clang --version | head -n 1 | perl -pe 's/http.*?//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
PROCS=$(nproc --all)
export KBUILD_COMPILER_STRING KBUILD_BUILD_USER KBUILD_BUILD_HOST PROCS

function compile() {
    START=$(date +"%s")
    make O=out ARCH=arm64 $DEFCONFIG
    make -kj"$PROCS" \
	O=out \
	ARCH=arm64 \
	CC=clang \
	LLVM=1 \
	LLVM_IAS=1 \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	V=$VERBOSE 2>&1 | tee error.log

    END=$(date +"%s")
    DIFF=$((END - START))

}
function zipping() {
    if [ ! -f "$IMAGE" ]; then
        telegram_push "error.log" "**Build Failed:** Kernel compilation threw errors"
        exit 1
    else
        mv "$IMAGE" AnyKernel3
        cd AnyKernel3 || exit 1
        zip -r9 "${FINAL_ZIP}" * -x .git README.md
        cd "$KERNEL_DIR" || exit 1
    fi
}
function upload() {
    telegram_push "AnyKernel3/${FINAL_ZIP}" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)"
    exit 0
}
# Main execution flow
compile
zipping
upload
