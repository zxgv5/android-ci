#!/bin/bash
# 本地测试构建脚本

set -e

echo "?? 本地测试构建BV项目"
echo "=================="

# 克隆源代码
if [ ! -d "source-code" ]; then
  echo "?? 克隆源代码仓库..."
  git clone --depth 1 --branch develop \
    https://github.com/fantasytyx/bv.git source-code
fi

cd source-code

# 检查gradlew权限
if [ ! -x "gradlew" ]; then
  chmod +x gradlew
fi

# 模拟GitHub Actions环境
echo "?? 设置环境变量..."
export SIGNING_PROPERTIES=../signing.properties
export KEYSTORE_PATH=../keystore.jks

# 运行构建
echo "???  开始构建..."
./gradlew clean assembleDebug  # 先构建debug版本测试

echo ""
echo "? 构建完成！"
echo "?? APK文件位置:"
find app/build/outputs/apk -name "*.apk" -type f | xargs ls -lh