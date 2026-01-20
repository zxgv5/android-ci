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

# 4、进度栏下方按钮，焦点逻辑顺序更改，首先落到“弹幕”上，方便控制弹幕启停
FANTASY_BV_CONTROLLERVIDEOINFO_KT="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
# 使用捕获组保留原缩进
sed -i 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' "$FANTASY_BV_CONTROLLERVIDEOINFO_KT"

# 5、隐藏左侧边栏中的“搜索”、“UGC”和“PGC”三个页面导航按钮，尤其是UGC和PGC，太卡了
FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/DrawerContent.kt"
sed -i \
  -e 's/^\([[:space:]]*\)DrawerItem\.Search,/\1\/\/DrawerItem.Search,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.UGC,/\1\/\/DrawerItem.UGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.PGC,/\1\/\/DrawerItem.PGC,/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"

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

# 8、尝试修复“动态”页长按下方向键焦点左移出区问题
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/shared/src/main/kotlin/dev/aaa1115910/bv/viewmodel/home" \
    "DynamicViewModel.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home" \
    "DynamicsScreen.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/videocard" \
    "SmallVideoCard.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# - - - - - - - - - - - - - - - - - -使用 awk 注释kt文件中的所有logger代码 - - - - - - - - - - - - - - - - - -
# 在${FANTASY_BV_SOURCE_ROOT}目录下搜索所有.kt文件，并注释掉含有logger相关内容的行
# import io.github.oshai.kotlinlogging.KotlinLogging
# import dev.aaa1115910.bv.util.fInfo
# KotlinLogging.logger {}
# androidLogger
# logger.info              147
# logger.fInfo             219
# logger.warn               24
# logger.fWarn              16
# logger.error              10
# logger.fError              9
# logger.exception           0
# logger.fException          9
echo "注释logger相关代码..."
find "${FANTASY_BV_SOURCE_ROOT}" -name "*.kt" -type f | while read kt_file; do
    # 检查文件是否存在
    if [[ -f "$kt_file" ]]; then
        # 创建临时文件
        tmp_file="${kt_file}.tmp"
        # 处理每一行，注释掉包含特定内容的行
        awk '
        function containsExactWord(line, word) {
            # 使用正则表达式进行全字匹配（单词边界）
            # \< 表示单词开始，\> 表示单词结束
            return match(line, "\\<" word "\\>")
        }
        {
            line = $0
            should_comment = 0
            # 检查是否包含特定内容（部分匹配，大小写敏感）
            if (line ~ /import[[:space:]]+io\.github\.oshai\.kotlinlogging\.KotlinLogging/) {
                should_comment = 1
            }
            if (line ~ /import[[:space:]]+dev\.aaa1115910\.bv\.util\.fInfo/) {
                should_comment = 1
            }
            if (line ~ /KotlinLogging\.logger[[:space:]]*\{/) {
                should_comment = 1
            }
            if (line ~ /logger\.fInfo/) {
                should_comment = 1
            }
            if (line ~ /logger\.info/) {
                should_comment = 1
            }
            if (line ~ /logger\.fWarn/) {
                should_comment = 1
            }
            if (line ~ /logger\.warn/) {
                should_comment = 1
            }
            if (line ~ /logger\.fError/) {
                should_comment = 1
            }
            if (line ~ /logger\.error/) {
                should_comment = 1
            }
            if (line ~ /logger\.fException/) {
                should_comment = 1
            }
            if (line ~ /logger\.exception/) {
                should_comment = 1
            }
            # 检查是否包含androidLogger（全字匹配，大小写敏感）
            if (containsExactWord(line, "androidLogger")) {
                should_comment = 1
            }
            # 如果应该注释且尚未被注释，则注释它
            if (should_comment && !match(line, /^[[:space:]]*\/\//)) {
                # 保留行首的缩进
                if (match(line, /^[[:space:]]*/)) {
                    indent = substr(line, RSTART, RLENGTH)
                    rest = substr(line, RLENGTH + 1)
                    print indent "//" rest
                    next
                }
            }
            print line
        }' "$kt_file" > "$tmp_file"
        # 如果文件有变化，替换原文件
        if ! cmp -s "$kt_file" "$tmp_file"; then
            mv "$tmp_file" "$kt_file"
            echo "已处理文件: $kt_file"
        else
            rm "$tmp_file"
        fi
    fi
done
echo "logger相关代码注释完成！"
