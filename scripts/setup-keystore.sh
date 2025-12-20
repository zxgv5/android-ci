#!/bin/bash
# 用于生成和编码keystore的脚本

set -e

echo "?? BV Android App Keystore Setup"
echo "================================"

# 生成keystore
keytool -genkey -v \
  -keystore bv-keystore.jks \
  -alias bv-release \
  -keyalg RSA \
  -keysize 3072 \
  -validity 10000

# 编码为base64
echo ""
echo "?? Base64 encoded keystore (复制到GitHub Secrets):"
echo "================================================"
base64 bv-keystore.jks

echo ""
echo "? 请将上面的base64文本保存为 BV_KEYSTORE_BASE64 secret"
echo ""
echo "其他需要设置的secrets:"
echo "1. BV_KEYSTORE_PWD: [您的密钥库密码]"
echo "2. BV_KEYSTORE_ALIAS: bv-release"
echo "3. BV_KEYSTORE_ALIAS_PWD: [您的别名密码]"

# 安全清理（可选）
read -p "是否删除本地keystore文件？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm bv-keystore.jks
  echo "???  本地keystore已删除"
fi