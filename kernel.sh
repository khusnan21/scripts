#!/bin/bash

# We're building Procyon.
cd ..

# Export compiler type
if [[ "$@" =~ "clang"* ]]; then
	export COMPILER="Clang 9.x"
elif [[ "$@" =~ "gcc10"* ]]; then
        export COMPILER="GCC 10 Experimental"
elif [[ "$@" =~ "gcc4.9"* ]]; then
	export COMPILER="GCC 4.9 Meme"
else
	export COMPILER="GCC 9.1 bare-metal"
fi

# Export correct version
if [[ "$@" =~ "beta"* ]]; then
	export TYPE=beta
	export VERSION="Procyon-Daisy-BETA-${RELEASE_VERSION}-rc${DRONE_BUILD_NUMBER}-${RELEASE_CODENAME}"
else
	export TYPE=stable
	export VERSION="Procyon-Daisy-Stable-${RELEASE_VERSION}-${RELEASE_CODENAME}"
fi

export ZIPNAME="${VERSION}.zip"

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi

# Post to CI channel
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Procyon Kernel</code>
Type: <code>${TYPE}</code>
Device: <code>MI A2 Lite (daisy)</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
Changelog: ${DRONE_REPO_LINK}/compare/$DRONE_COMMIT_BEFORE...$DRONE_COMMIT_AFTER
<i>Build started on Drone Cloud...</i>
Check the build status here: https://cloud.drone.io/nysascape/procyon_kernel_daisy/${DRONE_BUILD_NUMBER}" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build started for revision ${DRONE_BUILD_NUMBER}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML

# Make is shit so I have to pass thru some toolchains
# Let's build, anyway
PATH="/drone/src/clang/bin:${PATH}"
START=$(date +"%s")
make O=out ARCH=arm64 procyon_defconfig
if [[ "$@" =~ "clang"* ]]; then
        make -j${KEBABS} O=out ARCH=arm64 CC=clang CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/drone/src/gcc/bin/aarch64-linux-gnu-" CROSS_COMPILE_ARM32="/drone/src/gcc32/bin/arm-maestro-linux-gnueabi-"
elif [[ "$@" =~ "gcc10"* ]]; then
	make -j${KEBABS} O=out ARCH=arm64 CROSS_COMPILE="/drone/src/gcc/bin/aarch64-raphiel-elf-" CROSS_COMPILE_ARM32="/drone/src/gcc32/bin/arm-maestro-linux-gnueabi-"
elif [[ "$@" =~ "gcc4.9"* ]]; then
	make -j${KEBABS} O=out ARCH=arm64 CROSS_COMPILE="/drone/src/gcc/bin/aarch64-linux-android-"
else
	make -j${KEBABS} O=out ARCH=arm64 CROSS_COMPILE="/drone/src/gcc/bin/aarch64-elf-" CROSS_COMPILE_ARM32="/drone/src/gcc32/bin/arm-eabi-"
fi
END=$(date +"%s")
DIFF=$(( END - START))

cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel

# POST ZIP OR FAILURE
cd anykernel
zip -r9 ${ZIPNAME} *
CHECKER=$(ls -l ${ZIPNAME} | awk '{print $5}')

if (($((CHECKER / 1048576)) > 5)); then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for daisy (PLATINA GUYS DO NOT FLASH)" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
	curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Error in build!" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi

rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb

