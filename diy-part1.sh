#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 1. 修复 Actions 虚拟主机创建 swapfile 时的权限被拒问题
sudo chmod 777 / 2>/dev/null || true

# 2. 安全注入 DAED 第三方高性能代理软件源，规避 Git 冲突
echo 'src-git daeuniverse https://github.com/daeuniverse/openwrt-packages.git;main' >> feeds.conf.default
