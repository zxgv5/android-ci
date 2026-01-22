#!/bin/bash
# customize-bv-leonwu85.sh

set -e  # 遇到错误立即退出，避免ci静默失败
LEONWU85_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/leonwu85-bv-source"
# - - - - - - - - - - - - - - - - - -简单且无模糊的修改用sed等实现 - - - - - - - - - - - - - - - - - -
# 1、版本号规则调整，避免负数
# 2、修改包名
LEONWU85_BV_APPCONFIGURATION_KT="$LEONWU85_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
sed -i \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
  -e 's/const val applicationId = "dev.aaa1115910.bv2"/const val applicationId = "dev.leonwu85.bv"/' \
  "$LEONWU85_BV_APPCONFIGURATION_KT"

# 3、修改应用名
LEONWU85_BV_DEBUG_STRINGS_XML="$LEONWU85_BV_SOURCE_ROOT/app/shared/src/debug/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV Debug.*<\/string>/<string name="app_name">leonwu85 Debug<\/string>/' "$LEONWU85_BV_DEBUG_STRINGS_XML"

LEONWU85_BV_MAIN_STRINGS_XML="$LEONWU85_BV_SOURCE_ROOT/app/shared/src/main/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV.*<\/string>/<string name="app_name">leonwu85<\/string>/' "$LEONWU85_BV_MAIN_STRINGS_XML"

LEONWU85_BV_R8TEST_STRINGS_XML="$LEONWU85_BV_SOURCE_ROOT/app/shared/src/r8Test/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV R8 Test.*<\/string>/<string name="app_name">leonwu85 R8 Test<\/string>/' "$LEONWU85_BV_R8TEST_STRINGS_XML"

# 4、进度栏下方按钮，焦点逻辑顺序更改，首先落到“弹幕”上，方便控制弹幕启停
LEONWU85_BV_CONTROLLERVIDEOINFO_KT="$LEONWU85_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
sed -i 's/down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/down = focusRequesters["danmaku"] ?: FocusRequester()/' "$LEONWU85_BV_CONTROLLERVIDEOINFO_KT"

# 5、TV端倍速调整，并调整“设置”中的倍速范围
LEONWU85_BV_PLAYERSETTING_KT="${LEONWU85_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/settings/content/PlayerSetting.kt"
sed -i \
  -e 's/minValue = 0.25,/minValue = 0.2,/' \
  -e 's/maxValue = 2.5,/maxValue = 5.0,/' \
  -e 's/step = 0.25,/step = 0.2,/' \
  "$LEONWU85_BV_PLAYERSETTING_KT"

LEONWU85_BV_PICTUREMENU_KT="${LEONWU85_BV_SOURCE_ROOT}/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/playermenu/PictureMenu.kt"
sed -i \
  -e 's/step = 0.25f,/step = 0.2f,/' \
  -e 's/range = 0.25f..3f,/range = 0.2f..5f,/' \
  "$LEONWU85_BV_PICTUREMENU_KT"

# - - - - - - - - - - - - - - - - - -复杂或容易歧义的修改，用源文件替换实现 - - - - - - - - - - - - - - - - - -
CI_FILE_UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CI_FILE_UTILS_SCRIPT_DIR}/ci_file_utils.sh"

# 6、尝试修复“动态”页长按下方向键焦点左移出区问题
ci_source_patch \
    "${LEONWU85_BV_SOURCE_ROOT}/app/shared/src/main/kotlin/dev/aaa1115910/bv/viewmodel/home" \
    "DynamicViewModel.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_leonwu85"

ci_source_patch \
    "${LEONWU85_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home" \
    "DynamicsScreen.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_leonwu85"

ci_source_patch \
    "${LEONWU85_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/videocard" \
    "SmallVideoCard.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_leonwu85"

# - - - - - - - - - - - - - - - - - -注释logger相关代码 - - - - - - - - - - - - - - - - - -
# 使用python在${LEONWU85_BV_SOURCE_ROOT}目录下搜索所有.kt文件，并注释掉含有特定内容的行
echo "注释全部日志记录代码..."

PYTHON_AND_SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/comment_logger.py" "${LEONWU85_BV_SOURCE_ROOT}"

echo "logger相关代码注释完成！"