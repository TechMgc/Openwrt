#!/bin/bash
# Add a feed source
echo 'src-git design https://github.com/gngpp/luci-theme-design' >>feeds.conf.default

mkdir -p files/usr/share
mkdir -p files/etc/
touch files/etc/op_version
touch files/usr/share/opUpdate.sh

cat>deleteFiles.sh<<-\EOF
#!/bin/bash
rm -rf  bin/targets/x86/64/config.buildinfo
rm -rf  bin/targets/x86/64/feeds.buildinfo
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-kernel.bin
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.vmdk
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img.gz
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic.manifest
rm -rf  bin/targets/x86/64/profiles.json
exit 0
EOF

cat>op_version.sh<<-\EOOF
#!/bin/bash
op_version="V`date '+%y%m%d%H%M'`" 
echo $op_version >  files/etc/op_version  
grep "opUpdate.sh"  package/lean/default-settings/files/zzz-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/lean/default-settings/files/zzz-default-settings
	cat>> package/lean/default-settings/files/zzz-default-settings<<-EOF
	sed -i '$ a alias opupdate="sh /usr/share/opUpdate.sh"' /etc/profile
        exit 0
	EOF
fi
EOOF

cat>files/usr/share/opUpdate.sh<<-\EOF
#!/bin/bash
# https://github.com/Blueplanet20120/Actions-OpenWrt-x86
# Actions-OpenWrt-x86 By Lenyu 20210505
#path=$(dirname $(readlink -f $0))
# cd ${path}
#检测准备
if [ ! -f  "/etc/op_version" ]; then
	echo
	echo -e "\033[31m 找不到版本信息… \033[0m"
	echo
	exit 0
fi
rm -f /tmp/cloud_version
# 获取固件云端版本号、内核版本号信息
current_version=`cat /etc/op_version`
wget -qO- -t1 -T2 "https://api.github.com/repos/Blueplanet20120/Actions-OpenWrt-x86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
	openwrt_sta=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_sta.md5
	openwrt_sta_uefi=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_sta_uefi.md5
else
	echo "请检测网络或重试！"
	exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/openwrt_release | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type
echo
if [[ "$cloud_kernel" =~ "4.19" ]]; then
	echo
	echo -e "\033[31m 该脚本在Lenyu固件Sta版本上运行，目前只建议在Dev版本上运行，准备退出… \033[0m"
	echo
	exit 0
fi
#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		wget -P /tmp "$openwrt_sta" -O /tmp/openwrt_sta.md5
		cd /tmp && md5sum -c openwrt_sta.md5
		if [ $? != 0 ]; then
		  echo "您下载文件失败，请检查网络重试…"
		  sleep 4
		  exit
		fi
		gzip -d /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
else
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		wget -P /tmp "$openwrt_sta_uefi" -O /tmp/openwrt_sta_uefi.md5
		cd /tmp && md5sum -c openwrt_sta_uefi.md5
		if [ $? != 0 ]; then
			echo "您下载文件失败，请检查网络重试…"
			sleep 1
			exit
		fi
		gzip -d /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
fi

exit 0
EOF
