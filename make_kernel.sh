#!/bin/sh

# Automated make-kpkg for OpenVZ on Debian. Made with love by alex on 14/01/13
# Add some tests and an ugly way to get the last version of OpenVZ on 16/01/13
# version 0.2

# Licence: gnu.org/licenses/gpl.html
# Made for eNovance

clean_old_files () {
    ls | grep -v `basename $0` | grep -v README.md | xargs rm -rf {}\;
}

# ugly hack to find the last openvz version
find_version_kernel () {
    wget "http://download.openvz.org/kernel/branches/rhel6-2.6.32/current/kernel.spec"
    VZ=`grep "%define distro_build" kernel.spec | awk '{print $3}' | head -n 1`
    BUILD=`grep "%define buildid" kernel.spec | awk '{print $3}' | head -n 1`
    VERSION_VZ="$VZ""$BUILD"
    VERSION_KERNEL=2.6.32
}

test_find_version_kernel () {
    if [ "$VERSION_VZ" == "" ];then
        echo "Unable to found the last OpenVZ kernel version, exiting."
        exit 0
    fi
}

# download vanilla kernel
dl_vanilla_kernel () {
    wget "ftp://ftp.free.fr/pub/linux/kernel/v2.6/linux-"$VERSION_KERNEL".tar.gz"
}

test_dl_vanilla_kernel () {
    if [ ! -f linux-"$VERSION_KERNEL".tar.gz ];then
        echo "Unable to find the vanilla kernel tarball, exiting"
        exit 0
    else
        tar xvzf "linux-"$VERSION_KERNEL".tar.gz"
    fi
}

# download openvz config
dl_openvz_config () {
    wget "http://download.openvz.org/kernel/branches/rhel6-"$VERSION_KERNEL"/"$VERSION_VZ"/configs/config-"$VERSION_KERNEL"-"$VERSION_VZ".x86_64"
}

test_dl_openvz_config () {
    if [ ! -f config-"$VERSION_KERNEL"-"$VERSION_VZ".x86_64 ];then
        echo "Unable to find the kernel config, exiting"
        exit 0
    fi
}

# download openvz patch
dl_openvz_patch () {
    wget "http://download.openvz.org/kernel/branches/rhel6-"$VERSION_KERNEL"/"$VERSION_VZ"/patches/patch-"$VERSION_VZ"-combined.gz"
}

test_dl_openvz_patch () {
    if [ ! -f patch-"$VERSION_VZ"-combined.gz ];then
        echo "Unable to find the OpenVZ patch, exiting"
        exit 0
    else
        gzip -d "patch-"$VERSION_VZ"-combined.gz"
    fi
}
# patch da kernel
patch_kernel () {
    OLD_PWD=`pwd`
    cd linux-"$VERSION_KERNEL"/
    patch -p1 < ../patch-"$VERSION_VZ"-combined
    if [ $? != 0 ];then
        echo "Kernel patching exit with something different than 0, exiting"
        exit 0
    fi
    cd $OLD_PWD
}

modify_config () {
# copy da config
    cp config-"$VERSION_KERNEL"-"$VERSION_VZ".x86_64 config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
# modify some options on config
    #sed -i "s/CONFIG_EXPERIMENTAL=y/# CONFIG_EXPERIMENTAL is not set/" config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
    #sed -i "s/CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="$VERSION_VZ"/" config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
    sed -i "s/# CONFIG_MCORE2 is not set/CONFIG_MCORE2=y/" config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
    sed -i "s/CONFIG_GENERIC_CPU=y/# CONFIG_GENERIC_CPU is not set\nCONFIG_X86_INTEL_USERCOPY=y\nCONFIG_X86_USE_PPRO_CHECKSUM=y\nCONFIG_X86_P6_NOP=y/" config-"$VERSION_KERNEL"-"$VERSION_VZ"-eno.x86_64
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
    cd linux-"$VERSION_KERNEL" && make-kpkg --rootcmd fakeroot --jobs 24 --arch amd64 --append_to_version -ehaelix-amd64 --revision "$VERSION_KERNEL"-"$VERSION_VZ" --initrd kernel_image kernel_headers
}
clean_old_files
find_version_kernel
test_find_version_kernel
dl_vanilla_kernel
test_dl_vanilla_kernel
dl_openvz_config
test_dl_openvz_config
dl_openvz_patch
test_dl_openvz_patch
patch_kernel
modify_config
export_var
build_kernel
