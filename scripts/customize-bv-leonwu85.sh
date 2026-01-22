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
# LEONWU85_BV_CONTROLLERVIDEOINFO_KT="$LEONWU85_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
# 使用捕获组保留原缩进
# sed -i 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' "$LEONWU85_BV_CONTROLLERVIDEOINFO_KT"
