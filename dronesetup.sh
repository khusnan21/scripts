#!/bin/bash
cd ..

git clone https://github.com/nysadev/acrux-ak3 -b master anykernel

if [[ "$@" =~ "clang"* ]]; then
	git clone https://github.com/RaphielGang/aarch64-linux-gnu-8.x.git --depth=1 gcc
	git clone https://github.com/RaphielGang/arm-linux-gnueabi-8.x.git --depth=1 gcc32
	git clone https://github.com/RaphielGang/aosp-clang --depth=1 clang
elif [[ "$@" =~ "gcc10"* ]]; then
	git clone https://github.com/RaphielGang/aarch64-raph-linux-android -b elf --depth=1 gcc
	git clone https://github.com/baalajimaestro/arm-maestro-linux-gnueabi/ -b 240719 --depth=1 gcc32
else
	git clone https://github.com/kdrag0n/aarch64-elf-gcc -b 9.x --depth=1 gcc
	git clone https://github.com/kdrag0n/arm-eabi-gcc -b 9.x --depth=1 gcc32
fi
