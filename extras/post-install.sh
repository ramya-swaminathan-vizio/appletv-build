#!/bin/sh

cd "${0%/*}"

mkdir -p locales

chown conjure:system * */* */*/* */*/*/*


chmod 777 .
chmod 644 VERSION
chmod 755 post-install.sh
pushd ./basic-egl
chmod 755 setenv.sh basic-egl.sh basic-egl
chmod 755 app deleted
chmod 666 app_config.xml nadk-update-app-list libCoreADI.so libCoreFP.so libshim_lib.so 
popd

if false;then
pushd ./assets
chmod 644 *
popd

pushd ./chromecast_locales
chmod 644 *
popd

pushd ./lib
chmod 644 *
grep -q 5597 /linux_rootfs/basic/dtv_driver.ko
if [ $? -ne 0 ]; then
#FHD
ln -s libcast_avsettings_1.0.fhd.so libcast_avsettings_1.0.so
else
#UHD
ln -s libcast_avsettings_1.0.uhd.so libcast_avsettings_1.0.so
fi
popd
fi

