echo "==============================="
echo "开始执行 DIY 自定义脚本"
echo "==============================="

echo "克隆仓库"
git clone https://github.com/coolsnowwolf/lede
cd lede

# 只注释未被注释的带分支行，同时取消注释luci.git
sed -i -e '/^[^#].*luci\.git;openwrt-23\.05/s/^/#/' \
       -e '/^[^#].*luci\.git;openwrt-24\.10/s/^/#/' \
       -e '/^#src-git luci https:\/\/github\.com\/coolsnowwolf\/luci\.git$/s/^#//' feeds.conf.default

# 更新feeds.conf.default
./scripts/feeds update -a
./scripts/feeds install -a

echo "添加源"
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
git pull
./scripts/feeds update -a
./scripts/feeds install -a

# 1. 删除不需要的插件（举例）
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/kenzo/luci-app-argon-config
rm -rf feeds/kenzo/luci-app-adguardhome
rm -rf feeds/kenzo/luci-theme-argon
rm -rf feeds/kenzo/adguardhome

# 2. 修改默认IP（源码方式，二选一）
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/luci/bin/config_generate

# 3. 设置默认主题为 argon
sed -i "s/bootstrap/argon/g" feeds/luci/collections/luci/Makefile
sed -i "s/Bootstrap/argon/g" feeds/luci/collections/luci/Makefile

# 4. 修改固件品牌名称
sed -i 's/LEDE/OpenWrt/g' package/base-files/files/bin/config_generate
sed -i 's/LEDE/OpenWrt/g' package/lean/default-settings/files/zzz-default-settings

# 5. 修改 x86 内核版本为 5.4
echo "修改 x86 内核版本为 5.4..."

sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=5.4/' target/linux/x86/Makefile

echo "修改完成"

# 6. 添加插件
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/downloads/luci-theme-argon
git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package


# 7. 克隆仓库到 studio 目录
git clone https://github.com/mcusee/studio.git studio

echo "开始替换 PNG 文件..."

cp -f studio/icons/*.png feeds/luci/modules/luci-base/htdocs/luci-static/resources/icons/

echo "PNG 替换完成"

echo "下载 bg1.jpg..."

wget -O package/downloads/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg \
https://raw.githubusercontent.com/mcusee/studio/main/icons/bg1.jpg

echo "替换完成"

echo "==============================="
echo "DIY 脚本执行完成"
echo "==============================="