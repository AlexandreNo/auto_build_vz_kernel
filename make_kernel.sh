#!/bin/sh

# Automated make-kpkg for OpenVZ on Debian. Made with love by alex on 14/01/13
# version 0.1

# TODO:
# check dependencies: build-essential, kernel-packages, libncurses5-dev

VERSION_VZ=042stab068.8
VERSION_KERNEL=2.6.32

# download vanilla kernel
dl_vanilla_kernel () {
wget ftp://ftp.free.fr/pub/linux/kernel/v2.6/linux-"$VERSION_KERNEL".tar.gz
tar xvzf linux-"$VERSION_KERNEL".tar.gz
}

# download openvz config
dl_openvz_config () {
wget http://download.openvz.org/kernel/branches/rhel6-"$VERSION_KERNEL"/"$VERSION_VZ"/configs/config-"$VERSION_KERNEL"-"$VERSION_VZ".x86_64
}

# download openvz patch
dl_openvz_patch () {
wget http://download.openvz.org/kernel/branches/rhel6-"$VERSION_KERNEL"/"$VERSION_VZ"/patches/patch-"$VERSION_VZ"-combined.gz
gzip -d patch-"$VERSION_VZ"-combined.gz
}

# patch da kernel
patch_kernel () {
OLD_PWD=`pwd`
cd linux-"$VERSION_KERNEL"/ && patch -p1 < ../patch-"$VERSION_VZ"-combined && cd $OLD_PWD
}

modify_config () {
# copy da config
cp config-"$VERSION_KERNEL"-"$VERSION_VZ".x86_64 config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64

# modify some options on config
sed -i 's/CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="$VERSION_VZ/' config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
sed -i 's/# CONFIG_MCORE2 is not set/CONFIG_MCORE2=y/' config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
sed -i 's/CONFIG_GENERIC_CPU=y/# CONFIG_GENERIC_CPU is not set\nCONFIG_X86_INTEL_USERCOPY=y\nCONFIG_X86_USE_PPRO_CHECKSUM=y\nCONFIG_X86_P6_NOP=y/' config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64

# uncomment to disable building of annoying mlx modules
#sed -i 's/CONFIG_MLX4_EN=m/# CONFIG_MLX4_EN is not set/' config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
#sed -i 's/CONFIG_MLX4_CORE=m/# CONFIG_MLX4_CORE is not set/' config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
#sed -i 's/CONFIG_MLX4_DEBUG=y/# CONFIG_MLX4_DEBUG is not set/' config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
#sed -i 's/CONFIG_MLX4_INFINIBAND=m/# CONFIG_MLX4_INFINIBAND is not set/' config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64

# copy the modified config to use it :)
cp config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64 linux-"$VERSION_KERNEL/.config"
}

# export somes variables to make make-kpkg happy
export_var () {
export KPKG_MAINTAINER="eNovance Kernel Dream Team"
export KPKG_EMAIL="kernel@enovance.com"
}

build_kernel () {
cd linux-"$VERSION_KERNEL" && make-kpkg --jobs 24 --arch amd64 --append_to_version -ehaelix-amd64 --revision "$VERSION_KERNEL"-"$VERSION_VZ" --initrd kernel_image kernel_headers
}

dl_vanilla_kernel
dl_openvz_config
dl_openvz_patch
patch_kernel
modify_config
export_var
build_kernel
