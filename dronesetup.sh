#!/bin/bash
cd ..

git clone https://github.com/nysadev/acrux-ak3 -b daisy anykernel

if [[ "$@" =~ "clang"* ]]; then
	git clone https://github.com/RaphielGang/aarch64-linux-gnu-8.x.git --depth=1 gcc
        git clone https://github.com/baalajimaestro/arm-maestro-linux-gnueabi/ -b 240719 --depth=1 gcc32
	git clone https://github.com/RaphielGang/aosp-clang --depth=1 clang
elif [[ "$@" =~ "gcc10"* ]]; then
	git clone https://github.com/RaphielGang/aarch64-raph-linux-android -b elf --depth=1 gcc
        git clone https://github.com/baalajimaestro/arm-maestro-linux-gnueabi/ -b 240719 --depth=1 gcc32
elif [[ "$@" =~ "gcc4.9"* ]]; then
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 gcc
	cd gcc
	git reset --hard 75c0ace0eb9ba47c11df56971e7f63f2ebaa9fbd
	cd ..
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 gcc32
	cd gcc32
	git reset --hard 10ddded24ecdbdeaa4ac57d49962ca06e9c1ceaa
	cd ..
else
	git clone https://github.com/kdrag0n/aarch64-elf-gcc -b 9.x --depth=1 gcc
	git clone https://github.com/kdrag0n/arm-eabi-gcc -b 9.x --depth=1 gcc32
fi
