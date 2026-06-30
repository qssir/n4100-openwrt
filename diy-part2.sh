#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# =====================================================================
# 1. 基础系统与管理权对齐 (IP / 密码 / 主题)
# =====================================================================
# 修改默认后台管理 IP 为 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 【👑 终极密码权限修复】使用 uci-defaults 机制，在物理机首次开机时内部强行将密码锁定死为 password
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99_set_root_password
#!/bin/sh
printf "password\npassword\n" | passwd root
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

# 2.2 清理官方 Argon 自带的默认随机壁纸，强制系统只读取你在 files 目录里上传的专属主壁纸
ARGON_BG_DIR="feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background"
if [ -d "$ARGON_BG_DIR" ]; then
    echo "正在清理 Argon 默认背景，锁定专属壁纸..."
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
