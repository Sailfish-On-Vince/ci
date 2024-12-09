#!/bin/bash

set -x

source /home/mersdk/work/ci/ci/hadk.env
export ANDROID_ROOT=/home/mersdk/work/ci/ci/hadk_14.1

sudo chown -R mersdk:mersdk $ANDROID_ROOT
cd $ANDROID_ROOT

cd ~/.scratchbox2
cp -R SailfishOS-*-$PORT_ARCH $VENDOR-$DEVICE-$PORT_ARCH
cd $VENDOR-$DEVICE-$PORT_ARCH
sed -i "s/SailfishOS-$SAILFISH_VERSION/$VENDOR-$DEVICE/g" sb2.config
sudo ln -s /srv/mer/targets/SailfishOS-$SAILFISH_VERSION-$PORT_ARCH /srv/mer/targets/$VENDOR-$DEVICE-$PORT_ARCH
sudo ln -s /srv/mer/toolings/SailfishOS-$SAILFISH_VERSION /srv/mer/toolings/$VENDOR-$DEVICE

# 3.3.0.16 hack
sudo zypper in -y kmod ccache dos2unix
#sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R chmod 777 /boot

sdk-assistant list

cd $ANDROID_ROOT
sed -i '/CONFIG_NETFILTER_XT_MATCH_QTAGUID/d' hybris/mer-kernel-check/mer_verify_kernel_config

sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in -y ccache

# update dhd submodule and replace then
cd $ANDROID_ROOT
cd rpm/dhd
git pull origin master
git checkout 960d6af856c1ccc082d6a078c402d5d04ce2791e
cp /home/mersdk/work/ci/ci/helpers/*.sh $ANDROID_ROOT/rpm/dhd/helpers/
chmod +x $ANDROID_ROOT/rpm/dhd/helpers/*.sh
cp /home/mersdk/work/ci/ci/droid-hal-mido.spec $ANDROID_ROOT/rpm/
dos2unix $ANDROID_ROOT/rpm/droid-hal-mido.spec

# update dhc submodule
# cd $ANDROID_ROOT/hybris/droid-configs/droid-configs-device
# git pull origin master
# git checkout 0664f1a4ba7248332f5e3addb5ef3e63789452bd

cd $ANDROID_ROOT/droid-hal-version-mido
git pull origin master

cd $ANDROID_ROOT
# Add mido lost libs
git clone https://github.com/Sailfish-On-Vince/device_xiaomi_vince.git
cp device_xiaomi_vince/lostlibs/*.so out/target/product/mido/system/lib/
rm -rf device_xiaomi_vince

sudo mkdir -p /proc/sys/fs/binfmt_misc/
sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
rpm/dhd/helpers/build_packages.sh

if [ "$?" -ne 0 ];then
  # if failed, retry once
  rpm/dhd/helpers/build_packages.sh
  cat $ANDROID_ROOT/droid-hal-mido.log
fi
