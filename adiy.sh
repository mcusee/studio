echo "==============================="
echo "开始执行 DIY 自定义脚本"
echo "==============================="


if [ ! -d "lede" ]; then
    echo "未发现 lede 目录，开始克隆仓库..."
    git clone https://github.com/coolsnowwolf/lede
fi

cd lede || exit 1

echo "检查是否需要更新..."
git fetch origin

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/master)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "已经是最新状态"
else
    echo "检测到更新，开始同步..."
    git reset --hard origin/master
    echo "更新完成"
fi

echo "==============================="
echo "处理 feeds.conf.default 是否已是目标状态..."
echo "==============================="
if grep -q "^src-git luci https://github.com/coolsnowwolf/luci.git$" feeds.conf.default \
   && ! grep -q "^[^#].*luci\.git;openwrt-23\.05" feeds.conf.default \
   && ! grep -q "^[^#].*luci\.git;openwrt-24\.10" feeds.conf.default
then
    echo "已经是目标状态，跳过修改"
else
    echo "检测到未调整，开始修正..."

    sed -i \
        -e '/^[^#].*luci\.git;openwrt-23\.05/s/^/#/' \
        -e '/^[^#].*luci\.git;openwrt-24\.10/s/^/#/' \
        -e '/^#src-git luci https:\/\/github\.com\/coolsnowwolf\/luci\.git$/s/^#//' \
        feeds.conf.default

    echo "修改完成"
fi

echo "==============================="
echo "更新feeds.conf.default"
echo "==============================="
./scripts/feeds update -a
./scripts/feeds install -a

echo "========================================"
echo "添加软件源并更新更新feeds.conf.default"
echo "========================================"
if grep -q "github.com/kenzok8/openwrt-packages" feeds.conf.default; then
    echo "kenzo 已存在，跳过"
else
    echo "添加 kenzo..."
    sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
fi
echo "检查 small..."

if grep -q "github.com/kenzok8/small" feeds.conf.default; then
    echo "small 已存在，跳过"
else
    echo "添加 small..."
    sed -i '1i src-git small https://github.com/kenzok8/small' feeds.conf.default
fi
git pull
./scripts/feeds update -a
./scripts/feeds install -a

echo "========================================"
echo "删除不需要的插件"
echo "========================================"
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/kenzo/luci-app-argon-config
rm -rf feeds/kenzo/luci-app-adguardhome
rm -rf feeds/kenzo/luci-theme-argon
rm -rf feeds/kenzo/adguardhome

echo "========================================"
echo "修改本地文件"
echo "========================================"
echo "修改默认IP"
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/luci/bin/config_generate

echo "设置默认主题为 argon"
sed -i "s/bootstrap/argon/g" feeds/luci/collections/luci/Makefile
sed -i "s/Bootstrap/argon/g" feeds/luci/collections/luci/Makefile

echo "修改固件品牌名称"
sed -i 's/LEDE/OpenWrt/g' package/base-files/files/bin/config_generate
sed -i 's/LEDE/OpenWrt/g' package/base-files/luci/bin/config_generate
sed -i 's/LEDE/OpenWrt/g' package/lean/default-settings/files/zzz-default-settings

echo "修改 x86 内核版本为 5.4..."
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=5.4/' target/linux/x86/Makefile
echo "修改完成"

echo "==============================="
echo "添加插件"
echo "==============================="

# luci-theme-argon
if [ -d "package/downloads/luci-theme-argon" ]; then
    echo "luci-theme-argon 已存在，跳过"
else
    echo "正在克隆 luci-theme-argon..."
    git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/downloads/luci-theme-argon
fi

# luci-app-adguardhome
if [ -d "package/luci-app-adguardhome" ]; then
    echo "luci-app-adguardhome 已存在，跳过"
else
    echo "正在克隆 luci-app-adguardhome..."
    git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/luci-app-adguardhome
fi

echo "克隆仓库到 studio 目录"
rm -rf studio
git clone https://github.com/mcusee/studio.git studio
echo "开始替换 PNG 文件..."
cp -f studio/icons/*.png feeds/luci/modules/luci-base/htdocs/luci-static/resources/icons/
echo "PNG 替换完成"

echo "下载 bg1.jpg..."
wget -O package/downloads/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg \
https://raw.githubusercontent.com/mcusee/studio/main/icons/bg1.jpg
echo "替换完成"

wget -O .config https://raw.githubusercontent.com/mcusee/studio/main/.config

echo "==============================="
echo "DIY 脚本执行完成"
echo "==============================="