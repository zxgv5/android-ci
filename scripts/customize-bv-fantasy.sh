#!/bin/bash
# customize-bv-fantasy.sh

set -e  # 遇到错误立即退出，避免ci静默失败
FANTASY_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/fantasy-bv-source"
# - - - - - - - - - - - - - - - - - -简单且无模糊的修改用sed等实现 - - - - - - - - - - - - - - - - - -
# 1、版本号规则调整，避免负数
# 2、修改包名
FANTASY_BV_APPCONFIGURATION_KT="$FANTASY_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
sed -i \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
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
sed -i -e 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' \
       -e 's/^\([[:space:]]*\)step: Float = 0\.25f,/\1step: Float = 0.2f,/' \
       -e 's/^\([[:space:]]*\)min: Float = 0\.25f,/\1min: Float = 0.2f,/' \
       -e 's/^\([[:space:]]*\)max: Float = 3f,/\1max: Float = 5f,/' "$FANTASY_BV_CONTROLLERVIDEOINFO_KT"

# 5、隐藏左侧边栏中的“搜索”、“UGC”和“PGC”三个页面导航按钮，尤其是UGC和PGC，太卡了
FANTASY_BV_DRAWERCONTENT_KT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/DrawerContent.kt"
sed -i \
  -e 's/^\([[:space:]]*\)DrawerItem\.Search,/\1\/\/DrawerItem.Search,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.UGC,/\1\/\/DrawerItem.UGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.PGC,/\1\/\/DrawerItem.PGC,/' \
  "$FANTASY_BV_DRAWERCONTENT_KT"

# 6、隐藏顶部“追番”和“稍后看”两个导航标签
FANTASY_BV_TOPNAV_KT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/TopNav.kt"
sed -i \
  -e 's/^\([[:space:]]*\)Favorite("收藏"),[[:space:]]*$/\1Favorite("收藏");/' \
  -e 's/^\([[:space:]]*\)FollowingSeason("追番"),[[:space:]]*$/\/\/\1FollowingSeason("追番"),/' \
  -e 's/^\([[:space:]]*\)ToView("稍后看");[[:space:]]*$/\/\/\1ToView("稍后看");/' \
  "$FANTASY_BV_TOPNAV_KT"

# - - - - - - - - - - - - - - - - - -复杂或容易歧义的修改，用源文件替换实现 - - - - - - - - - - - - - - - - - -
CI_FILE_UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CI_FILE_UTILS_SCRIPT_DIR}/ci_file_utils.sh"

# 5、对MainScreen.kt进行覆盖，配合上面对隐藏左侧边栏中的“搜索”、“UGC”和“PGC”三个页面导航按钮所作修改
#    同时注释掉其中的logger和finfo
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens" \
    "MainScreen.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# 6、对HomeContent.kt进行覆盖，配合上面对隐藏顶部“追番”和“稍后看”两个导航标签所作修改
#    同时注释掉其中的logger和finfo
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main" \
    "HomeContent.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# 7、TV端倍速调整，对PictureMenu.kt进行覆盖，调整倍速设置
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/playermenu" \
    "PictureMenu.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/settings/content" \
    "PlayerSetting.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# - - - - - - - - - - - - - - - - - -更加灵活和后期易变的修改，用python处理实现 - - - - - - - - - - - - - - - - - -
# 使用python处理如下几个*Screen.kt文件，解决视频列表加载和焦点左漂问题
echo "处理*Screen.kt代码..."

PYTHON_AND_SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FANTASY_BV_DYNAMICSSCREEN_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_dynamicsscreen_kt.py" "${FANTASY_BV_DYNAMICSSCREEN_KT}"

FANTASY_BV_POPULARSCREEN_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/PopularScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_popularscreen_kt.py" "${FANTASY_BV_POPULARSCREEN_KT}"

FANTASY_BV_RECOMMENDSCREEN_KT="${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/RecommendScreen.kt"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/patch_recommendscreen_kt.py" "${FANTASY_BV_RECOMMENDSCREEN_KT}"

echo "*Screen.kt代码处理完成..."

# 目前可以确定仅修改*Screen.kt即可解决加载慢和焦点漂移问题
# 下面进行进一步进一步调试，以便找到最小有效修改
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/user" \
    "HistoryScreen.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"


# 8、尝试修复“动态”页长按下方向键焦点左移出区问题
# ci_source_patch \
#     "${FANTASY_BV_SOURCE_ROOT}/app/shared/src/main/kotlin/dev/aaa1115910/bv/viewmodel/home" \
#     "DynamicViewModel.kt" \
#     "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# ci_source_patch \
#     "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home" \
#     "DynamicsScreen.kt" \
#     "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# ci_source_patch \
#     "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/videocard" \
#     "SmallVideoCard.kt" \
#     "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# 9、尝试修复“推荐”页长按下方向键焦点左移出区问题
# ci_source_patch \
#     "${FANTASY_BV_SOURCE_ROOT}/app/shared/src/main/kotlin/dev/aaa1115910/bv/viewmodel/home" \
#     "RecommendViewModel.kt" \
#     "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# ci_source_patch \
#     "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home" \
#     "RecommendScreen.kt" \
#     "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

#10、尝试修复“热门”页长按下方向键焦点左移出区问题
# ci_source_patch \
#     "${FANTASY_BV_SOURCE_ROOT}/app/shared/src/main/kotlin/dev/aaa1115910/bv/viewmodel/home" \
#     "PopularViewModel.kt" \
#     "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# ci_source_patch \
#     "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home" \
#     "PopularScreen.kt" \
#     "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# - - - - - - - - - - - - - - - - - -使用 awk 注释kt文件中的所有logger代码 - - - - - - - - - - - - - - - - - -
# 在${FANTASY_BV_SOURCE_ROOT}目录下搜索所有.kt文件，并注释掉含有logger相关内容的行
# 其中app/shared/src/main/kotlin/dev/aaa1115910/bv/repository/UserRepository.kt需要特殊处理，里面有跨行的logger.info{}表达式

# import io.github.oshai.kotlinlogging.KotlinLogging
# import dev.aaa1115910.bv.util.fInfo
# KotlinLogging.logger
# logger("BvVideoPlayer")
# logger("BvPlayer")
# androidLogger
# logger.info              147
# logger.fInfo             219
# logger.warn               24
# logger.fWarn              16
# logger.error              10
# logger.fError              9
# logger.exception           0
# logger.fException          9
# logger.debug               8
# logger.fDebug              1

# - - - - - - - - - - - - - - - - - -注释logger相关代码 - - - - - - - - - - - - - - - - - -
# 使用python在${FANTASY_BV_SOURCE_ROOT}目录下搜索所有.kt文件，并注释掉含有特定内容的行
echo "注释全部日志记录代码..."

#PYTHON_AND_SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "${PYTHON_AND_SHELL_SCRIPT_DIR}/comment_logger.py" "${FANTASY_BV_SOURCE_ROOT}"

echo "logger相关代码注释完成！"