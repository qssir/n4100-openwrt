#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# =====================================================================
# 👑 0. 强行把全家桶核心配置追加到系统基础模板中（防止被 defconfig 恶意擦除）
# =====================================================================
echo "=== 正在对内核底座应用配置锁定锁 ==="
cat << 'EOF' >> .config
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y
CONFIG_PACKAGE_kmod-fuse=y
CONFIG_PACKAGE_fuse-utils=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_docker-compose=y
CONFIG_PACKAGE_luci-app-alist=y
CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_luci-app-minidlna=y
CONFIG_PACKAGE_luci-app-qbittorrent=y
CONFIG_PACKAGE_luci-app-transmission=y
CONFIG_PACKAGE_luci-app-aria2=y
CONFIG_PACKAGE_daed=y
CONFIG_PACKAGE_luci-app-daed=y
CONFIG_PACKAGE_luci-i18n-daed-zh-cn=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-app-n2n=y
CONFIG_PACKAGE_luci-app-softethervpn=y
CONFIG_PACKAGE_luci-app-ipsec-vpnd=y
CONFIG_PACKAGE_luci-app-syncdial=y
CONFIG_PACKAGE_luci-app-eqos=y
CONFIG_PACKAGE_luci-app-wrtbwmon=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-filebrowser=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_TARGET_KERNEL_PARTSIZE=128
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
# CONFIG_DEVEL is not set
# CONFIG_TOOLCHAINOPTS is not set
EOF


# =====================================================================
# 1. 基础系统与管理权对齐 (IP / 密码 / 主题)
# =====================================================================
# 修改默认后台管理 IP 为 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 【👑 终极密码与专属壁纸开机联合置入锁】使用标准的 uci-defaults 机制
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99_set_root_password
#!/bin/sh
# 1.1 强行锁定默认登录密码为 password
printf "password\npassword\n" | passwd root

# 1.2 物理壁纸跨线搬运：将 files 里的 wall.jpg 注入到 Argon 主题的核心缓存区
TARGET_BG_DIR="/www/luci-static/argon/background"
mkdir -p $TARGET_BG_DIR
if [ -f "/etc/uci-defaults/wall.jpg" ]; then
    cp -f /etc/uci-defaults/wall.jpg $TARGET_BG_DIR/wall.jpg
    chmod 644 $TARGET_BG_DIR/wall.jpg
fi

# 1.3 👑 影视聚合起飞补丁：在后台建立独立的延迟触发任务，静默拉取 Docker 项目
(
    sleep 60
    echo "=== 开始静默构建 AList 影视聚合 Docker 项目 ==="
    bash -c "$(curl -sSLf https://ailg.ggbond.org/xy_install.sh)"
) &

exit 0
EOF
chmod +x files/etc/uci-defaults/99_set_root_password

# 使用安全的 uci-defaults 注入法切换 Argon 主题
cat << 'EOF' > files/etc/uci-defaults/30_luci-theme-argon
#!/bin/sh
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci
exit 0
EOF
chmod +x files/etc/uci-defaults/30_luci-theme-argon


# =====================================================================
# 2. 🎨 Argon 主题深度视觉魔改与专属品牌定制
# =====================================================================
# 2.1 强行把浏览器标签页的默认标题从 "ImmortalWrt" 替换为你的专属名称 "BleachWrt"
TITLE_FILE="feeds/luci/modules/luci-base/luasrc/view/header.htm"
if [ -f "$TITLE_FILE" ]; then
    echo "正在将系统标签页全局标题修改为 BleachWrt..."
    sed -i 's/- 开源路由系统/- 乐享安全网关/g' $TITLE_FILE 2>/dev/null || true
fi

# 2.2 清理官方 Argon 自带的默认随机壁纸
ARGON_BG_DIR="feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background"
if [ -d "$ARGON_BG_DIR" ]; then
    echo "正在清理 Argon 默认背景..."
    rm -rf $ARGON_BG_DIR/*
fi


# =====================================================================
# 3. 🎬 4K 高码率大文件局域网播放吞吐量深度调优
# =====================================================================
# 3.1 注入标准 sysctl 内核网络栈与内存隔离补丁
mkdir -p files/etc/sysctl.d
cat << 'EOF' > files/etc/sysctl.d/99-4k-media-optimize.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=33554432
net.core.wmem_default=33554432
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
vm.dirty_background_ratio=5
vm.dirty_ratio=10
vm.vfs_cache_pressure=50
EOF

# 3.2 深度优化 Samba4 传输配置文件
SMB_CONF="feeds/luci/applications/luci-app-samba4/root/etc/config/samba4"
if [ -f "$SMB_CONF" ]; then
    sed -i "/config samba/a \\\tlist server_multi_channel_support 'yes'" $SMB_CONF
    sed -i "/config samba/a \\\tlist rpc_daemon_smbd 'embedded'" $SMB_CONF
    sed -i "/config samba/a \\\tlist aio_read_size '4096'" $SMB_CONF
    sed -i "/config samba/a \\\tlist aio_write_size '4096'" $SMB_CONF
    sed -i "/config samba/a \\\tlist read_raw 'yes'" $SMB_CONF
    sed -i "/config samba/a \\\tlist write_raw 'yes'" $SMB_CONF
    sed -i "/config samba/a \\\tlist use_sendfile 'yes'" $SMB_CONF
fi

# 3.3 注入开机自启脚本补丁 (1T SSD 块设备 16MB 预读)
mkdir -p files/etc/init.d
cat << 'EOF' > files/etc/init.d/media_io_init
#!/bin/sh /etc/rc.common
START=99

start() {
    for dev in sda sdb nvme0n1; do
        if [ -b "/dev/$dev" ]; then
            echo "none" > /sys/block/$dev/queue/scheduler 2>/dev/null || true
            blockdev --setra 16384 /dev/$dev 2>/dev/null || true
        fi
    done
    modprobe tcp_bbr 2>/dev/null || true
}
EOF
chmod +x files/etc/init.d/media_io_init

# 3.4 注入定时计划任务
mkdir -p files/etc/crontabs
cat << 'EOF' >> files/etc/crontabs/root
30 4 * * * sync && echo 3 > /proc/sys/vm/drop_caches
0 5 * * * reboot
EOF
