#!/bin/bash

# We're building Acrux.
cd ..

# Export compiler type
if [[ "$@" =~ "clang"* ]]; then
	export COMPILER="Clang 9.x"
else
	export COMPILER="GCC 9.1 bare-metal"
fi

# Export correct version
if [[ "$@" =~ "beta"* ]]; then
	export TYPE=beta
	export VERSION="Acrux-BETA-${RELEASE}-${BUILDNUMBER}-${CODENAME}"
	# Be careful if something changes LOCALVERSION line
        sed -i "50s/.*/CONFIG_LOCALVERSION=\"-Acrux-${RELEASE}-${DRONE_BUILD_NUMBER}-${CODENAME}\"/g" arch/arm64/configs/acrux_defconfig
	export INC="$(echo ${RC} | grep -o -E '[0-9]+')"
	INC="$((INC + 1))"
	sed -i "2s/.*/rc$INC/g" CURRENTVERSION
else
	export TYPE=stable
	export VERSION="Acrux-Stable-${RELEASE_VERSION}-${RELEASE_CODENAME}"
        # Be careful if something changes LOCALVERSION line
        sed -i "50s/.*/CONFIG_LOCALVERSION=\"-Acrux-${RELEASE_VERSION}-${RELEASE_CODENAME}\"/g" arch/arm64/configs/acrux_defconfig
fi

export ZIPNAME="${VERSION}.zip"

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi

# Post to CI channel
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Acrux Kernel</code>
Type: <code>${TYPE}</code>
Device: <code>MI 8 Lite (platina)</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build started on Drone_CI....</i>" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build started for revision ${DRONE_BUILD_NUMBER}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML

# Make is shit so I have to pass thru some toolchains
# Let's build, anyway
PATH="/drone/src/clang/bin:${PATH}"
START=$(date +"%s")
make O=out ARCH=arm64 acrux_defconfig
if [[ "$@" =~ "clang"* ]]; then
        make -j${KEBABS} O=out ARCH=arm64 CC=clang CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/drone/src/gcc/bin/aarch64-linux-gnu-" CROSS_COMPILE_ARM32="/drone/src/gcc32/bin/arm-linux-gnueabi-"
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
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for Platina" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
	curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for platina throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi

rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb

