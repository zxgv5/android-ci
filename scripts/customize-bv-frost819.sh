#!/bin/bash
# customize-bv-frost819.sh

set -e  # 遇到错误立即退出，避免CI静默失败

FROST819_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/frost819-bv-source"

# 修改 AppConfiguration.kt 中的配置项
# 版本号规则调整，避免负数
# 修改包名
# 修改sdk的最低版本为23，避免和其他库的链接问题
FROST819_BV_APPCONFIGURATION_KT="$FROST819_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
# 修改 AppConfiguration.kt 中的配置项
sed -i \
  -e 's/const val minSdk = 21/const val minSdk = 23/' \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
  -e 's/const val applicationId = "dev.frost819.bv"/const val applicationId = "dev.f819.bv"/' \
  "$FROST819_BV_APPCONFIGURATION_KT"

# 修改应用名
FROST819_BV_DEBUG_STRINGS_XML="$FROST819_BV_SOURCE_ROOT/app/src/debug/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV Debug.*<\/string>/<string name="app_name">f819 Debug<\/string>/' "$FROST819_BV_DEBUG_STRINGS_XML"

FROST819_BV_MAIN_STRINGS_XML="$FROST819_BV_SOURCE_ROOT/app/src/main/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV.*<\/string>/<string name="app_name">f819<\/string>/' "$FROST819_BV_MAIN_STRINGS_XML"

FROST819_BV_R8TEST_STRINGS_XML="$FROST819_BV_SOURCE_ROOT/app/src/r8Test/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV R8 Test.*<\/string>/<string name="app_name">f819 R8 Test<\/string>/' "$FROST819_BV_R8TEST_STRINGS_XML"


# - - - - - - - - - - - - - - - - - -注释logger相关代码 - - - - - - - - - - - - - - - - - -
# 使用python在${FROST819_BV_SOURCE_ROOT}目录下搜索所有.kt文件，并注释掉含有特定内容的行
echo "注释全部日志记录代码..."

PYTHON_AND_SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/comment_logger.py" "${FROST819_BV_SOURCE_ROOT}"

echo "logger相关代码注释完成！"