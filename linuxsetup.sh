#!/bin/bash
# Copyright (C) 2019 The Raphielscape Company LLC.
#
# Licensed under the Raphielscape Public License, Version 1.c (the "License");
# you may not use this file except in compliance with the License.
#
# nysascape's Linux setup script for my installs.
# Currently there is no support for distros other than Debian.

# Let's install some packages
sudo apt-get -y install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5-dev libsdl1.2-dev libssl-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev

# Clone in my aliases
git clone https://github.com/nysascape/aliases ~/aliases
sed -i 's#.bash_aliases#aliases/aliases#g' ~/.bashrc
source ~/.bashrc

# Git configurations
git config --global user.name "khusnan21"
git config --global user.email "khusnan21@gmail.com"
git config --global credential.helper store

# GCC 9 is always a good thing to have
git clone https://github.com/kdrag0n/aarch64-elf-gcc -b 9.x --depth=1 ~/gcc9
git clone https://github.com/kdrag0n/arm-eabi-gcc -b 9.x --depth=1 ~/gcc932

# Clone repo (thanks to LineageOS Wiki)
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# Add platform tools to PATH
wget -O ~/tools.zip https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -d ~/.platform_tools ~/tools.zip
echo "if [ -d "$HOME/.platform_tools/platform-tools" ] ; then" >> ~/.profile
echo "    PATH="$HOME/.platform_tools/platform-tools:$PATH"" >> ~/.profile
echo "fi" >> ~/.profile
source ~/.profile
rm ~/tools.zip
