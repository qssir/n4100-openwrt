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

# 修改默认密码为 password
sed -i 's/root:::0:99999:7:::/root:$1$O9mCis8O$8GPrlP7QpE1mQ79fI2n64\.:18888:0:99999:7:::/g' package/base-files/files/etc/shadow

# 强制默认主题为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile


# =====================================================================
# 2. 🎬 4K 高码率大文件局域网播放吞吐量深度调优
# =====================================================================

# 2.1 注入标准 sysctl 内核网络栈与内存隔离补丁 (解决大缓存卡顿与高码率掉帧)
mkdir -p package/base-files/files/etc/sysctl.d
cat << 'EOF' > package/base-files/files/etc/sysctl.d/99-4k-media-optimize.conf
# 开启 BBR 拥塞控制算法
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# 极大扩展网络套接字读写缓冲区，防止 4K 蓝光峰值码率瞬时突发导致掉包
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=33554432
net.core.wmem_default=33554432
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864

# 优化内存脏页控制，防止大规模 IO (如qb/tm下载) 占用过多内存阻塞 AList 影视流
vm.dirty_background_ratio=5
vm.dirty_ratio=10
vm.vfs_cache_pressure=50
EOF


# 2.2 深度优化 Samba4 传输配置文件 (逐行安全 sed 注入，开启 1MB 块传输与 AIO 异步)
SMB_CONF="feeds/luci/applications/luci-app-samba4/root/etc/config/samba4"
if [ -f "$SMB_CONF" ]; then
    # 注入全局优化参数，解决大文件播放抖动
    sed -i "/config samba/a \\\tlist server_multi_channel_support 'yes'" $SMB_CONF
    sed -i "/config samba/a \\\tlist rpc_daemon_smbd 'embedded'" $SMB_CONF
    sed -i "/config samba/a \\\tlist aio_read_size '4096'" $SMB_CONF
    sed -i "/config samba/a \\\tlist aio_write_size '4096'" $SMB_CONF
    sed -i "/config samba/a \\\tlist read_raw 'yes'" $SMB_CONF
    sed -i "/config samba/a \\\tlist write_raw 'yes'" $SMB_CONF
    sed -i "/config samba/a \\\tlist use_sendfile 'yes'" $SMB_CONF
fi


# 2.3 注入开机自启脚本补丁 (实现 1T SSD 块设备 16MB 预读 + 动态内存释放保护)
mkdir -p package/base-files/files/etc/init.d
cat << 'EOF' > package/base-files/files/etc/init.d/media_io_init
#!/bin/sh /etc/rc.common
START=99

start() {
    # 针对原生大容量 1T SSD 块设备（通常为 sda 或 nvme0n1）强行拉满 16MB 预读缓冲区 (16384 sectors)
    for dev in sda sdb nvme0n1; do
        if [ -b "/dev/$dev" ]; then
            echo "none" > /sys/block/$dev/queue/scheduler 2>/dev/null || true
            blockdev --setra 16384 /dev/$dev 2>/dev/null || true
        fi
    done
    
    # 确保内核成功加载 tcp_bbr 模块
    modprobe tcp_bbr 2>/dev/null || true
}
EOF
chmod +x package/base-files/files/etc/init.d/media_io_init


# 2.4 注入定时计划任务 (每天凌晨自动化清理内存与重启缓存，维持内网广播全天候生命体征)
mkdir -p package/base-files/files/etc/crontabs
cat << 'EOF' >> package/base-files/files/etc/crontabs/root
30 4 * * * sync && echo 3 > /proc/sys/vm/drop_caches
0 5 * * * reboot
EOF
