#!/bin/bash
# customize-bv-fantasy.sh

set -e  # 遇到错误立即退出，避免ci静默失败
FANTASY_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/fantasy-bv-source"
PYTHON_AND_SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# - - - - - - - - - - - - - - - - - -简单且无模糊的修改用sed等实现 - - - - - - - - - - - - - - - - - -
# 1、版本号规则调整，避免负数
# 2、修改包名
FANTASY_BV_APPCONFIGURATION_KT="$FANTASY_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
# sed -i \
#   -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
#   -e 's/const val applicationId = "dev.aaa1115910.bv2"/const val applicationId = "dev.fantasy.bv"/' \
#   "$FANTASY_BV_APPCONFIGURATION_KT"
sed -i \
  -e 's/const val applicationId = "dev.aaa1115910.bv2"/const val applicationId = "dev.fantasy.bv"/' \
  "$FANTASY_BV_APPCONFIGURATION_KT"

# 3、修改应用名
FANTASY_BV_DEBUG_STRINGS_XML="$FANTASY_BV_SOURCE_ROOT/app/shared/src/debug/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV Debug.*<\/string>/<string name="app_name">fantasy Debug<\/string>/' "$FANTASY_BV_DEBUG_STRINGS_XML"

FANTASY_BV_MAIN_STRINGS_XML="$FANTASY_BV_SOURCE_ROOT/app/shared/src/main/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV.*<\/string>/<string name="app_name">fantasy<\/string>/' "$FANTASY_BV_MAIN_STRINGS_XML"

FANTASY_BV_R8TEST_STRINGS_XML="$FANTASY_BV_SOURCE_ROOT/app/shared/src/r8Test/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV R8 Test.*<\/string>/<string name="app_name">fantasy R8 Test<\/string>/' "$FANTASY_BV_R8TEST_STRINGS_XML"

# 4、进度栏下方按钮，焦点逻辑顺序更改，首先落到“弹幕”上，方便控制弹幕启停，同时配合倍速按钮取值调整
# FANTASY_BV_CONTROLLERVIDEOINFO_KT="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
# sed -i 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' "$FANTASY_BV_CONTROLLERVIDEOINFO_KT"
FANTASY_BV_CONTROLLERVIDEOINFO_KT="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
# 使用捕获组保留原缩进
sed -i -e 's/^\([[:space:]]*\)down = firstVisibleButtonId?.let { focusRequesters\[it\] } ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' \
       -e 's/^\([[:space:]]*\)step: Float = 0\.25f,/\1step: Float = 0.2f,/' \
       -e 's/^\([[:space:]]*\)min: Float = 0\.25f,/\1min: Float = 0.2f,/' \
       -e 's/^\([[:space:]]*\)max: Float = 3f,/\1max: Float = 5f,/' "$FANTASY_BV_CONTROLLERVIDEOINFO_KT"

FANTASY_BV_PLAYERSETTING_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/settings/content/PlayerSetting.kt"
sed -i \
  -e 's/minValue = 0.25,/minValue = 0.2,/' \
  -e 's/maxValue = 2.5,/maxValue = 5.0,/' \
  -e 's/step = 0.25,/step = 0.2,/' \
  "$FANTASY_BV_PLAYERSETTING_KT"

FANTASY_BV_PICTUREMENU_KT="${FANTASY_BV_SOURCE_ROOT}/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/playermenu/PictureMenu.kt"
sed -i \
  -e 's/step = 0.25f,/step = 0.2f,/' \
  -e 's/range = 0.25f..3f,/range = 0.2f..5f,/' \
  "$FANTASY_BV_PICTUREMENU_KT"

# 5、隐藏左侧边栏中的“搜索”、“UGC”、“PGC”和“直播”等四个页面导航按钮，尤其是UGC和PGC，太卡了
FANTASY_BV_DRAWERCONTENT_KT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/DrawerContent.kt"
sed -i \
  -e 's/^\([[:space:]]*\)DrawerItem\.Search,/\1\/\/DrawerItem.Search,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.Home,/\1DrawerItem.Home/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.UGC,/\1\/\/DrawerItem.UGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.PGC,/\1\/\/DrawerItem.PGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.Live/\1\/\/DrawerItem.Live/' \
  "$FANTASY_BV_DRAWERCONTENT_KT"
# 配套修改
FANTASY_BV_MAINSCREEN_KT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/MainScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_mainscreen_kt.py" "${FANTASY_BV_MAINSCREEN_KT}"

# 6、隐藏顶部“追番”和“稍后看”两个导航标签
# 源仓库已增加可见设置项，此处的修改不再保留
# FANTASY_BV_TOPNAV_KT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/TopNav.kt"
# sed -i \
#   -e 's/^\([[:space:]]*\)Favorite("收藏"),[[:space:]]*$/\1Favorite("收藏");/' \
#   -e 's/^\([[:space:]]*\)FollowingSeason("追番"),[[:space:]]*$/\/\/\1FollowingSeason("追番"),/' \
#   -e 's/^\([[:space:]]*\)ToView("稍后看");[[:space:]]*$/\/\/\1ToView("稍后看");/' \
#   "$FANTASY_BV_TOPNAV_KT"
# FANTASY_BV_HOMECONTENT_KT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/HomeContent.kt"
# python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_homecontent_kt.py" "${FANTASY_BV_HOMECONTENT_KT}"

# 7、解决视频列表加载和焦点左漂问题
echo "处理*Screen.kt代码..."

FANTASY_BV_DYNAMICSSCREEN_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_dynamicsscreen_kt.py" "${FANTASY_BV_DYNAMICSSCREEN_KT}"

FANTASY_BV_POPULARSCREEN_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/PopularScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_popularscreen_kt.py" "${FANTASY_BV_POPULARSCREEN_KT}"

FANTASY_BV_RECOMMENDSCREEN_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/RecommendScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_recommendscreen_kt.py" "${FANTASY_BV_RECOMMENDSCREEN_KT}"

FANTASY_BV_HISTORYSCREEN_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/user/HistoryScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_historyscreen_kt.py" "${FANTASY_BV_HISTORYSCREEN_KT}"

echo "*Screen.kt代码处理完成..."
# - - - - - - - - - - - - - - - - - -注释logger相关代码 - - - - - - - - - - - - - - - - - -
# 8、使用python在${FANTASY_BV_SOURCE_ROOT}目录下搜索所有.kt文件，并注释掉含有特定内容的行
echo "注释全部日志记录代码..."

#PYTHON_AND_SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/comment_logger.py" "${FANTASY_BV_SOURCE_ROOT}"

echo "logger相关代码注释完成！"