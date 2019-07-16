#!/bin/bash

# We're building Acrux.
cd /home/nysadev/acrux

# Set up some version exports
export RELEASE="$(awk NR==1 CURRENTVERSION)"
export RC="$(awk NR==2 CURRENTVERSION)"
export CODENAME="$(awk NR==3 CURRENTVERSION)"

# Export correct version
if [[ $1 == "beta" ]]; then
	export VERSION="Acrux-BETA-${RELEASE}-${RC}-${CODENAME}"
	# Be careful if something changes LOCALVERSION line
        sed -i "50s/.*/CONFIG_LOCALVERSION=\"Acrux-${RELEASE}-${RC}-${CODENAME}\"/g" arch/arm64/configs/acrux_defconfig
	export INC="$(echo ${RC} | grep -o -E '[0-9]+')"
	INC="$((INC + 1))"
	sed -i "2s/.*/rc$INC/g" CURRENTVERSION
else
	export VERSION="Acrux-Stable-${RELEASE}-${CODENAME}"
        # Be careful if something changes LOCALVERSION line
        sed -i "50s/.*/CONFIG_LOCALVERSION=\"Acrux-${RELEASE}-${CODENAME}\"/g" arch/arm64/configs/acrux_defconfig
        export INC="$(echo ${RELEASE} | grep -o -E '[0-9]+')"
        INC="$((INC + 1))"
        sed -i "1s/.*/r$INC/g" CURRENTVERSION
fi

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi

# Make is shit so I have to pass thru some toolchains
# Let's build, anyway
START=$(date +"%s")
PATH="/home/nysadev/clang/bin:/home/nysadev/aarch64-linux-android-4.9/bin:${PATH}"
make -j${KEBABS} acrux_defconfig O=out
make -j${KEBABS} CC=clang CROSS_COMPILE=aarch64-linux-android- CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=/home/nysadev/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- O=out
END=$(date +"%s")
DIFF=$((START - END))
# Check to see if the kernel actually built
if [ -e out/arch/arm64/boot/Image.gz-dtb ]; then
        green=`tput setaf 2`
        reset=`tput sgr0`
        cp out/arch/arm64/boot/Image.gz-dtb ../Acrux-AK3
        cd ../Acrux-AK3
        zip -r9 ${VERSION} *
        echo ""   
        echo "${green}Kernel compile finished in ${DIFF}s!${reset}"
else
        red=`tput setaf 1`
        reset=`tput sgr0`
        echo ""   
        echo "${red}Kernel failed to build!${reset}
fi
