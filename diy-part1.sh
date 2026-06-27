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

# daeuniverse/openwrt-packages 仓库已不存在（404），删除此 feed
# 如需 daed 软件，请寻找替代 feed 源
# echo 'src-git-full daeuniverse https://github.com/daeuniverse/openwrt-packages.git;main' >> feeds.conf.default
