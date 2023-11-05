#!/bin/bash -xe

set -o errexit

. function.sh

YUM=dnf
RELEASEVER=${RELEASEVER:-8}
arch=${ARCH:-$(uname -m)}
MIRROR_URL=http://dl.rockylinux.org/pub/rocky/

install_wget

rootfs=$(pwd)/rootfs
if [[ -e $rootfs ]]; then
  rm -rf $rootfs
fi

key_rpm=rocky-gpg-keys-8.8-1.8.el8.noarch.rpm
repo_rpm=rocky-repos-8.8-1.8.el8.noarch.rpm

base_url=${MIRROR_URL}/$RELEASEVER/BaseOS/${arch}/os/Packages/r/

wget $base_url/$repo_rpm
wget $base_url/$key_rpm

mkdir -p $rootfs

rpm --root $rootfs --initdb
rpm --nodeps --root $rootfs -ivh $repo_rpm
rpm --nodeps --root $rootfs -ivh $key_rpm

rpm --root $rootfs --import  $rootfs/etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

$YUM --forcearch $arch -y --releasever $RELEASEVER --installroot=$rootfs --setopt=tsflags='nodocs' \
    --setopt=install_weak_deps=False \
    install dnf glibc-minimal-langpack langpacks-en glibc-langpack-en
echo "tsflags=nodocs" >> $rootfs/etc/dnf/dnf.conf

cp /etc/resolv.conf $rootfs/etc/resolv.conf

chroot $rootfs /bin/bash <<EOF
dnf --forcearch $arch -y --releasever $RELEASEVER install yum
dnf clean all
EOF


rm -f $rootfs/etc/resolv.conf

tar -C $rootfs -c . > image-$arch.tar
