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

# 4、TV端倍速范围调整
# 使用sed的上下文匹配，确保只修改VideoPlayerPictureMenuItem.PlaySpeed相关的行
FANTASY_BV_PICTUREMENU_KT="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/playermenu/PictureMenu.kt"
sed -i '/VideoPlayerPictureMenuItem\.PlaySpeed ->/,/^[[:space:]]*)/s/range = 0\.25f\.\.3f/range = 0.25f..5f/' "$FANTASY_BV_PICTUREMENU_KT"

# 5、进度栏下方按钮，焦点逻辑顺序更改，首先落到“弹幕”上，方便控制弹幕启停
FANTASY_BV_CONTROLLERVIDEOINFO_KT="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
# 使用捕获组保留原缩进
sed -i 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' "$FANTASY_BV_CONTROLLERVIDEOINFO_KT"

# 6、隐藏左侧边栏中的“搜索”、“UGC”和“PGC”三个页面导航按钮，尤其是UGC和PGC，太卡了
FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/DrawerContent.kt"
sed -i \
  -e 's/^\([[:space:]]*\)DrawerItem\.Search,/\1\/\/DrawerItem.Search,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.UGC,/\1\/\/DrawerItem.UGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.PGC,/\1\/\/DrawerItem.PGC,/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"

# 7、隐藏顶部“追番”和“稍后看”两个导航标签
FANTASY_BV_TOPNAV_KT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/TopNav.kt"
sed -i \
  -e 's/^\([[:space:]]*\)Favorite("收藏"),[[:space:]]*$/\1Favorite("收藏");/' \
  -e 's/^\([[:space:]]*\)FollowingSeason("追番"),[[:space:]]*$/\/\/\1FollowingSeason("追番"),/' \
  -e 's/^\([[:space:]]*\)ToView("稍后看");[[:space:]]*$/\/\/\1ToView("稍后看");/' \
  "$FANTASY_BV_TOPNAV_KT"

# - - - - - - - - - - - - - - - - - -复杂或容易歧义的修改，用源文件替换实现 - - - - - - - - - - - - - - - - - -
CI_FILE_UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CI_FILE_UTILS_SCRIPT_DIR}/ci_file_utils.sh"

# 6、对MainScreen.kt进行覆盖，配合上面对隐藏左侧边栏中的“搜索”、“UGC”和“PGC”三个页面导航按钮所作修改
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens" \
    "MainScreen.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
# 7、对HomeContent.kt进行覆盖，配合上面对隐藏顶部“追番”和“稍后看”两个导航标签所作修改
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main" \
    "HomeContent.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
# 8、尝试修复“动态”页长按下方向键焦点左移出区问题
ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component" \
    "TvLazyVerticalGrid.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

ci_source_patch \
    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home" \
    "DynamicsScreen.kt" \
    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"

# 开始启用TvLazyVerticalGrid对LazyVerticalGrid的替代
# 设置 TV 模块源码目录
FANTASY_BV_TV_SOURCE_DIR="$GITHUB_WORKSPACE/fantasy-bv-source/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv"
echo "🔍 开始搜索替换 TV 模块中的 LazyVerticalGrid → TvLazyVerticalGrid"
# 计数器
total_files=0
total_replacements=0
# 查找所有 .kt 文件，并排除可能的构建目录
find "$FANTASY_BV_TV_SOURCE_DIR" -type f -name "*.kt" \
    -not -path "*/build/*" \
    -not -path "*/.gradle/*" \
    -not -path "*/.idea/*" | while read file; do
    # 检查文件是否包含 LazyVerticalGrid（全字匹配）
    if grep -q "\bLazyVerticalGrid\b" "$file"; then
        ((total_files++))
        echo "📄 处理文件: ${file#$FANTASY_BV_TV_SOURCE_DIR/}"
        # 备份原文件
        cp "$file" "$file.bak"
        # 0. 注释掉 LazyVerticalGrid 的导入
        sed -i 's/^import androidx.compose.foundation.lazy.grid.LazyVerticalGrid$/\/\/ import androidx.compose.foundation.lazy.grid.LazyVerticalGrid/' "$file"
        # 1. 替换代码中的 LazyVerticalGrid
        sed -i 's/\bLazyVerticalGrid\b/TvLazyVerticalGrid/g' "$file"
        # 统计替换数量
        count=$(grep -o "\bLazyVerticalGrid\b" "$file.bak" | wc -l)
        ((total_replacements+=count))
        # 2. 检查是否需要添加 TvLazyVerticalGrid 导入
        if grep -q "TvLazyVerticalGrid" "$file" && ! grep -q "import dev.aaa1115910.bv.tv.component.TvLazyVerticalGrid" "$file"; then
            # 找到最后一个 import 语句的位置，在其后添加新导入
            last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
            if [ -n "$last_import_line" ]; then
                # 在最后一个 import 后添加新导入
                sed -i "${last_import_line}a import dev.aaa1115910.bv.tv.component.TvLazyVerticalGrid" "$file"
            else
                # 如果没有 import 语句，在 package 声明后添加
                package_line=$(grep -n "^package " "$file" | head -1 | cut -d: -f1)
                if [ -n "$package_line" ]; then
                    sed -i "${package_line}a import dev.aaa1115910.bv.tv.component.TvLazyVerticalGrid" "$file"
                else
                    # 如果没有 package 声明，在文件开头添加
                    sed -i "1i import dev.aaa1115910.bv.tv.component.TvLazyVerticalGrid" "$file"
                fi
            fi
            echo "   ➕ 添加了 TvLazyVerticalGrid 导入"
        fi
        echo "   🔄 替换了 $count 处 LazyVerticalGrid"
        # 3. 清理可能被注释的其他 LazyVerticalGrid 导入
        sed -i 's/^import androidx.compose.foundation.lazy.grid.LazyVerticalGrid\b.*$/\/\/ &/' "$file"
    fi
done
echo "✅ 替换完成！"
echo "📊 统计："
echo "   - 处理文件数: $total_files"
echo "   - 总替换次数: $total_replacements"
# 验证替换结果
echo "🔍 验证替换结果："

# 检查是否还有未注释的 LazyVerticalGrid 导入
remaining_imports=$(find "$FANTASY_BV_TV_SOURCE_DIR" -type f -name "*.kt" \
    -not -path "*/build/*" \
    -not -path "*/.gradle/*" \
    -not -path "*/.idea/*" \
    -exec grep -l "^import androidx.compose.foundation.lazy.grid.LazyVerticalGrid" {} \; | wc -l)

if [ $remaining_imports -eq 0 ]; then
    echo "✅ 所有 LazyVerticalGrid 导入已成功注释！"
else
    echo "⚠️  仍有 $remaining_imports 个文件包含未注释的 LazyVerticalGrid 导入"
    # 列出具体文件
    find "$FANTASY_BV_TV_SOURCE_DIR" -type f -name "*.kt" \
        -not -path "*/build/*" \
        -not -path "*/.gradle/*" \
        -not -path "*/.idea/*" \
        -exec grep -l "^import androidx.compose.foundation.lazy.grid.LazyVerticalGrid" {} \; | while read file; do
        echo "   ❌ ${file#$FANTASY_BV_TV_SOURCE_DIR/}"
    done
fi

# 检查是否还有代码中的 LazyVerticalGrid
remaining_code=$(find "$FANTASY_BV_TV_SOURCE_DIR" -type f -name "*.kt" \
    -not -path "*/build/*" \
    -not -path "*/.gradle/*" \
    -not -path "*/.idea/*" \
    -exec grep -l "\bLazyVerticalGrid\b" {} \; | wc -l)

if [ $remaining_code -eq 0 ]; then
    echo "✅ 所有代码中的 LazyVerticalGrid 已成功替换！"
else
    echo "⚠️  仍有 $remaining_code 个文件在代码中使用 LazyVerticalGrid"
    # 列出具体文件
    find "$FANTASY_BV_TV_SOURCE_DIR" -type f -name "*.kt" \
        -not -path "*/build/*" \
        -not -path "*/.gradle/*" \
        -not -path "*/.idea/*" \
        -exec grep -l "\bLazyVerticalGrid\b" {} \; | while read file; do
        echo "   ❌ ${file#$FANTASY_BV_TV_SOURCE_DIR/}"
    done
fi

# 检查所有使用 TvLazyVerticalGrid 的文件是否都有正确导入
echo "🔍 检查 TvLazyVerticalGrid 导入情况："
no_import_count=0
find "$FANTASY_BV_TV_SOURCE_DIR" -type f -name "*.kt" \
    -not -path "*/build/*" \
    -not -path "*/.gradle/*" \
    -not -path "*/.idea/*" \
    -exec grep -l "\bTvLazyVerticalGrid\b" {} \; | while read file; do
    if ! grep -q "import dev.aaa1115910.bv.tv.component.TvLazyVerticalGrid" "$file"; then
        ((no_import_count++))
        echo "   ⚠️  缺少导入: ${file#$FANTASY_BV_TV_SOURCE_DIR/}"
    fi
done

if [ $no_import_count -eq 0 ]; then
    echo "✅ 所有使用 TvLazyVerticalGrid 的文件都有正确导入！"
else
    echo "⚠️  有 $no_import_count 个文件使用了 TvLazyVerticalGrid 但缺少导入"
fi

# 备份文件统计
backup_count=$(find "$FANTASY_BV_TV_SOURCE_DIR" -name "*.kt.bak" -type f | wc -l)
echo "📁 备份文件数: $backup_count"

echo ""
echo "🚀 脚本执行完成！建议进行以下验证："
echo "1. 检查上述警告（如果有）"
echo "2. 运行项目编译测试"
echo "3. 确认焦点问题是否解决"
echo "4. 确认其他页面（推荐、热门）加载是否正常"



#ci_source_patch \
#    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens" \
#    "TagScreen.kt" \
#    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
#
#ci_source_patch \
#    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/util" \
#    "ProvideListBringIntoViewSpec.kt" \
#    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
#
#ci_source_patch \
#    "${FANTASY_BV_SOURCE_ROOT}/app/shared/src/main/kotlin/dev/aaa1115910/bv/viewmodel/home" \
#    "DynamicViewModel.kt" \
#    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
#
#ci_source_patch \
#    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/videocard" \
#    "SmallVideoCard.kt" \
#    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
#
#ci_source_patch \
#    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/videocard" \
#    "LargeVideoCard.kt" \
#    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
#
#ci_source_patch \
#    "${FANTASY_BV_SOURCE_ROOT}/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/videocard" \
#    "VideosRow.kt" \
#    "${GITHUB_WORKSPACE}/ci_source/patches/bv_fantasy"
