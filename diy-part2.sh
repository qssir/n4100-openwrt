#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# 1. 修改默认后台管理 IP 为 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 2. 修改默认密码为 password（暗号加密化写入，用户名原生默认为 root）
sed -i 's/root:::0:99999:7:::/root:$1$O9mCis8O$8GPrlP7QpE1mQ79fI2n64\.:18888:0:99999:7:::/g' package/base-files/files/etc/shadow

# 3. 强制默认主题为高颜值 Argon 主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
