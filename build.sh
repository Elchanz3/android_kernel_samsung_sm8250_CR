#!/bin/bash

mkdir kout
mkdir images
mkdir builds
export CDIR="$(pwd)"
export LOG_FILE=puppy.log
export OUT_DIR="/home/chanz22/Documentos/GitHub/android_kernel_samsung_sm8250_CR/kout"
export AK3="/home/chanz22/Documentos/GitHub/android_kernel_samsung_sm8250_CR/AnyKernel3"
export IMAGE_NAME=PuppyKernel
export KERNELZIP="PuppyKernel.zip"
export KERNELVERSION=0.1

# gcc exec format
export GCC_EXEC=aarch64-zyc-linux-gnu-

# ccache exec
export CCACHE=ccache

# Toolchains path
export CLANG_DIR=/home/chanz22/tc/Clang-20.0.0/bin/
export LLVM_DIR="$(CLANG_DIR)"
export GCC_PATH=/home/chanz22/tc/aarch64-zyc-linux-gnu-14/bin/"$GCC_EXEC"

DATE_START=$(date +"%s")

make O="$OUT_DIR" LLVM=1 LLVM_IAS=1 kona-perf_defconfig r8q.config
make O="$OUT_DIR" LLVM=1 LLVM_IAS=1 -j12 2>&1 | tee "../$LOG_FILE"

cp "$OUT_DIR"/arch/arm64/boot/Image "$AK3"/Image

export IMAGE="$AK3"/Image

echo ""
echo ""
echo "******************************************"
echo ""
echo "Checking for required files..."
echo ""
echo "******************************************"

if [ ! -f "$IMAGE" ]; then
    echo "Compilation failed. Required file '$IMAGE' not found. Check logs."
    exit 1
else
    echo "File '$IMAGE' found. Proceeding to the next step."
fi

echo "Required files found. Proceeding to the next step."

echo ""
echo ""
echo "******************************************"
echo ""
echo "Generating Anykernel3 zip..."
echo ""
echo "******************************************"

rm -r AnyKernel3/*.zip

if [[ -f "$IMAGE" ]]; then
    KERNELZIP="PuppyKernel.zip"

    (cd "AnyKernel3" && zip -r9 "$KERNELZIP" .) || error_exit "Error creating the AnyKernel package"

    echo "Zip done..."
fi

    cd AnyKernel3

    mv "$KERNELZIP" "$CDIR"/builds/PuppyKernel"$KERNELVERSION".zip

echo ""
echo "proceeding to step 2..."
echo ""
echo "******************************************"
echo ""
echo "generating flashable image..."
echo ""
echo "******************************************"

# clean up previous images
cd "$CDIR"/AIK
./cleanup.sh
./unpackimg.sh --nosudo

# back to main dir
cd "$CDIR"

# move generated files to temporary directory
mv "$AK3"/Image "$CDIR"/images/Image
mv "$CDIR"/images/Image "$CDIR"/images/boot.img-kernel

# cleanup past files and move new ones
rm "$CDIR"/AIK/split_img/boot.img-kernel
mv "$CDIR"/images/boot.img-kernel "$CDIR"/AIK/split_img/boot.img-kernel

# delete images dir
rm -r "$CDIR"/images

# goto AIK dir and repack boot.img as not sudo
cd "$CDIR"/AIK
./repackimg.sh --nosudo

# goto main dir
cd "$CDIR"

# move generated image to builds dir renamed as Puppykernel
mv "$CDIR"/AIK/image-new.img "$CDIR"/builds/"$IMAGE_NAME".img

if [ -d "kout" ]; then
    rm -rf "kout"
    echo "directory removed.."
else
    echo "pff. There is no 'kout' directory."
fi

echo "image done.."

    DATE_END=$(date +"%s")
    DIFF=$(($DATE_END - $DATE_START))
   
   echo -e "\nElapsed time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.\n"

echo "find your zip and image in build dir..."
