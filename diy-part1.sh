#!/bin/bash
# Add a feed source
echo 'src-git design https://github.com/gngpp/luci-theme-design' >>feeds.conf.default

mkdir -p files/usr/share
mkdir -p files/etc/
mkdir wget
touch files/etc/op_version
touch files/usr/share/opupdate.sh

cat>deletefiles.sh<<-\EOF
#!/bin/bash
rm -rf  bin/targets/x86/64/config.buildinfo
rm -rf  bin/targets/x86/64/feeds.buildinfo
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-kernel.bin
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.vmdk
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img.gz
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic.manifest
rm -rf  bin/targets/x86/64/profiles.json
rm -rf  bin/targets/x86/64/sha256sums
tag_version=`cat files/etc/op_version`
echo $tag_version >  wget/tag_version
openwrtefi=openwrt-x86-64-generic-squashfs-combined-efi.img.gz
cd bin/targets/x86/64
md5sum $openwrtefi > openwrt-efi.md5
exit 0
EOF

cat>opversion.sh<<-\EOOF
#!/bin/bash
op_version="V`date '+%y%m%d%H%M'`" 
echo $op_version >  files/etc/op_version  
grep "opupdate.sh"  package/lean/default-settings/files/zzz-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/lean/default-settings/files/zzz-default-settings
	cat>> package/lean/default-settings/files/zzz-default-settings<<-EOF
	sed -i '$ a alias opupdate="sh /usr/share/opupdate.sh"' /etc/profile
        chmod +x /usr/share/opupdate.sh
        exit 0
	EOF
fi
EOOF

cat>files/usr/share/opupdate.sh<<-\EOF
#!/bin/bash
#检测准备
if [ ! -f  "/etc/op_version" ]; then
	echo
	echo -e "\033[31m 找不到本地版本信息… \033[0m"
	echo
	exit 0
fi
rm -f /tmp/cloud_version
# 获取固件云端版本号、本地版本号信息
current_version=`cat /etc/op_version`
wget -qO- -t1 -T2 "https://api.github.com/repos/TechMgc/Openwrt/releases/latest" | grep "tag_name" | cut -d '"' -f4 > /tmp/cloud_version
if [ -s  "/tmp/cloud_version" ]; then
	#固件下载地址
	cloud_version=`cat /tmp/cloud_version`
	DOWNLOAD_URL=https://github.com/TechMgc/Openwrt/releases/download/${cloud_version}/openwrt-x86-64-generic-squashfs-combined-efi.img.gz
	openwrtefi=https://github.com/TechMgc/Openwrt/releases/download/${cloud_version}/openwrt-efi.md5
else
	echo "无法获取到云端版本号！"
	exit 1
fi
#md5值验证，固件类型判断
if [ "$current_version" != "$cloud_version" ];then
	wget -P /tmp "$DOWNLOAD_URL" -O /tmp/openwrt-x86-64-generic-squashfs-combined-efi.img.gz
	wget -P /tmp "$openwrtefi" -O /tmp/openwrt-efi.md5
	cd /tmp && md5sum -c openwrt-efi.md5
		if [ $? != 0 ]; then
			echo "您下载固件失败，请检查网络重试!"
			sleep 1
			exit
		fi
	gzip -d /tmp/openwrt-x86-64-generic-squashfs-combined-efi.img.gz
	sysupgrade /tmp/openwrt-x86-64-generic-squashfs-combined-efi.img
else
	echo -e "\033[32m 已经是最新版本! \033[0m"
	echo
	exit
fi

exit 0
EOF
