#!/bin/bash
# customize-bv-fantasy.sh

# ========== 核心调试配置（保留，确保set -e生效） ==========
set -eEx
trap '
  echo -e "\n====================================="
  echo -e "           ERROR DEBUG INFO           "
  echo -e "====================================="
  echo "  执行失败的命令: $BASH_COMMAND"
  echo "  命令退出码: $?"
  echo "  出错行号: $LINENO"
  echo "  脚本文件: $BASH_SOURCE"
  echo "  当前工作目录: $(pwd)"
  echo -e "=====================================\n"
  exit 1
' ERR

# ========== 原有变量定义 ==========
FANTASY_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/fantasy-bv-source"

# 修改 AppConfiguration.kt 中的配置项
FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION="$FANTASY_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION"
if [ ! -f "$FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
  -e 's/const val applicationId = "dev.aaa1115910.bv2"/const val applicationId = "dev.fantasy.bv"/' \
  "$FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION"
# 新增：验证修改是否生效（包名修改+版本号计算逻辑修改）
echo "[DEBUG] 验证 AppConfiguration.kt 修改结果..."
grep -q 'const val applicationId = "dev.fantasy.bv"' "$FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION"
grep -q '"git rev-list --count HEAD".exec().toInt() + 1' "$FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION"
echo "[DEBUG] 处理完成: AppConfiguration.kt（修改验证通过）"

# 修改应用名（debug）
FANTASY_BV_SOURCE_ASSDRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/debug/res/values/strings.xml"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_ASSDRV_STRINGS"
if [ ! -f "$FANTASY_BV_SOURCE_ASSDRV_STRINGS" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV Debug.*<\/string>/<string name="app_name">fantasy Debug<\/string>/' "$FANTASY_BV_SOURCE_ASSDRV_STRINGS"
# 新增：验证应用名修改
echo "[DEBUG] 验证 debug strings.xml 修改结果..."
grep -q '<string name="app_name">fantasy Debug</string>' "$FANTASY_BV_SOURCE_ASSDRV_STRINGS"
echo "[DEBUG] 处理完成: debug strings.xml（修改验证通过）"

# 修改应用名（main）
FANTASY_BV_SOURCE_ASSMRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/main/res/values/strings.xml"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_ASSMRV_STRINGS"
if [ ! -f "$FANTASY_BV_SOURCE_ASSMRV_STRINGS" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV.*<\/string>/<string name="app_name">fantasy<\/string>/' "$FANTASY_BV_SOURCE_ASSMRV_STRINGS"
# 新增：验证应用名修改
echo "[DEBUG] 验证 main strings.xml 修改结果..."
grep -q '<string name="app_name">fantasy</string>' "$FANTASY_BV_SOURCE_ASSMRV_STRINGS"
echo "[DEBUG] 处理完成: main strings.xml（修改验证通过）"

# 修改应用名（r8Test）
FANTASY_BV_SOURCE_ASSRRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/r8Test/res/values/strings.xml"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_ASSRRV_STRINGS"
if [ ! -f "$FANTASY_BV_SOURCE_ASSRRV_STRINGS" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV R8 Test.*<\/string>/<string name="app_name">fantasy R8 Test<\/string>/' "$FANTASY_BV_SOURCE_ASSRRV_STRINGS"
# 新增：验证应用名修改
echo "[DEBUG] 验证 r8Test strings.xml 修改结果..."
grep -q '<string name="app_name">fantasy R8 Test</string>' "$FANTASY_BV_SOURCE_ASSRRV_STRINGS"
echo "[DEBUG] 处理完成: r8Test strings.xml（修改验证通过）"

# 修复动态页面焦点问题（Python脚本）
FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
CI_CUSTOMIZE_SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT="$CI_CUSTOMIZE_SCRIPTS_DIR/modify_bv_fantasy_dynamics_screen.py"
echo -e "\n[DEBUG] 脚本所在目录: $CI_CUSTOMIZE_SCRIPTS_DIR"

echo -e "\n===== 检查python环境 ====="
if ! command -v python3 &> /dev/null; then
  echo "错误：未找到python3，请检查ci流程中的python安装步骤！"
  exit 1
fi
python3 --version

echo -e "\n===== 准备执行python脚本：$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT ====="
if [ ! -f "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT" ]; then
  echo "错误：python脚本不存在！"
  exit 1
fi
if [ ! -f "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN" ]; then
  echo "错误：目标文件不存在！"
  exit 1
fi

echo -e "\n===== 执行python脚本处理DynamicsScreen.kt ====="
python3 "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT" "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"
if [ $? -eq 0 ]; then
  echo -e "\n===== python脚本执行成功 ====="
else
  echo "错误：python脚本执行失败！"
  exit 1
fi
# 新增：验证Python脚本的修改结果（焦点逻辑关键特征）
echo "[DEBUG] 验证 DynamicsScreen.kt Python修改结果..."
grep -q 'import androidx.tv.foundation.focus.FocusRestriction' "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"
grep -q 'focusRestrict(FocusRestriction.Scrollable)' "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"
grep -q 'gridFocusRequester = remember { FocusRequester() }' "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"
echo "[DEBUG] 处理完成: DynamicsScreen.kt（Python修改验证通过）"

# 处理 libs.versions.toml
FANTASY_BV_SOURCE_GRADLE_LVT="$FANTASY_BV_SOURCE_ROOT/gradle/libs.versions.toml"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_GRADLE_LVT"
if [ ! -f "$FANTASY_BV_SOURCE_GRADLE_LVT" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i \
  -e '/zxing = "3.5.3"/a\androidxComposeBom = "2025.12.00"\nandroidxTvFoundation = "1.1.0"' \
  -e '/zxing = { module = "com.google.zxing:core", version.ref = "zxing" }/a\\n# Compose BOM\androidx-compose-bom = { module = "androidx.compose:compose-bom", version.ref = "androidxComposeBom" }\n# AndroidX TV Foundation\androidx-tv-foundation = { module = "androidx.tv:tv-foundation", version.ref = "androidxTvFoundation" }' \
  "$FANTASY_BV_SOURCE_GRADLE_LVT"
# 新增：验证修改结果
echo "[DEBUG] 验证 libs.versions.toml 修改结果..."
grep -q 'androidxComposeBom = "2025.12.00"' "$FANTASY_BV_SOURCE_GRADLE_LVT"
grep -q 'androidx-tv-foundation = { module = "androidx.tv:tv-foundation", version.ref = "androidxTvFoundation" }' "$FANTASY_BV_SOURCE_GRADLE_LVT"
echo "[DEBUG] 处理完成: libs.versions.toml（修改验证通过）"

# 处理 player/tv/build.gradle.kts
FANTASY_BV_SOURCE_PT_BGK="$FANTASY_BV_SOURCE_ROOT/player/tv/build.gradle.kts"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_PT_BGK"
if [ ! -f "$FANTASY_BV_SOURCE_PT_BGK" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i \
  -e '/dependencies {/a\    val composeBom = platform(libs.androidx.compose.bom)\n    implementation(composeBom)\n    androidTestImplementation(composeBom)' \
  -e 's/implementation(androidx.compose.tv.foundation)/implementation(libs.androidx.tv.foundation)/' \
  "$FANTASY_BV_SOURCE_PT_BGK"
# 新增：验证修改结果
echo "[DEBUG] 验证 player/tv/build.gradle.kts 修改结果..."
grep -q 'val composeBom = platform(libs.androidx.compose.bom)' "$FANTASY_BV_SOURCE_PT_BGK"
grep -q 'implementation(libs.androidx.tv.foundation)' "$FANTASY_BV_SOURCE_PT_BGK"
echo "[DEBUG] 处理完成: player/tv/build.gradle.kts（修改验证通过）"

# TV端倍速范围调整
FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/playermenu/PictureMenu.kt"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU"
if [ ! -f "$FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i '/VideoPlayerPictureMenuItem\.PlaySpeed ->/,/^[[:space:]]*)/s/range = 0\.25f\.\.3f/range = 0.25f..5f/' "$FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU"
# 新增：验证倍速范围修改
echo "[DEBUG] 验证 PictureMenu.kt 倍速范围修改结果..."
grep -q 'range = 0.25f..5f' "$FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU"
echo "[DEBUG] 处理完成: PictureMenu.kt（修改验证通过）"

# 焦点逻辑更改（弹幕优先）
FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO"
if [ ! -f "$FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' "$FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO"
# 新增：验证焦点逻辑修改
echo "[DEBUG] 验证 ControllerVideoInfo.kt 焦点逻辑修改结果..."
grep -q 'down = focusRequesters["danmaku"] ?: FocusRequester()' "$FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO"
echo "[DEBUG] 处理完成: ControllerVideoInfo.kt（修改验证通过）"

# 隐藏左边侧边栏页面
FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/DrawerContent.kt"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"
if [ ! -f "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i \
  -e 's/^\([[:space:]]*\)DrawerItem\.Search,/\1\/\/DrawerItem.Search,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.UGC,/\1\/\/DrawerItem.UGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.PGC,/\1\/\/DrawerItem.PGC,/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"
# 新增：验证侧边栏隐藏
echo "[DEBUG] 验证 DrawerContent.kt 侧边栏隐藏修改结果..."
grep -q '//DrawerItem.Search,' "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"
grep -q '//DrawerItem.UGC,' "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"
grep -q '//DrawerItem.PGC,' "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"
echo "[DEBUG] 处理完成: DrawerContent.kt（修改验证通过）"

# 隐藏顶上导航标签
FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/TopNav.kt"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV"
if [ ! -f "$FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
sed -i \
  -e 's/^\([[:space:]]*\)Favorite("收藏"),[[:space:]]*$/\1Favorite("收藏");/' \
  -e 's/^\([[:space:]]*\)FollowingSeason("追番"),[[:space:]]*$/\/\/\1FollowingSeason("追番"),/' \
  -e 's/^\([[:space:]]*\)ToView("稍后看");[[:space:]]*$/\/\/\1ToView("稍后看");/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV"
# 新增：验证导航标签隐藏
echo "[DEBUG] 验证 TopNav.kt 导航标签隐藏修改结果..."
grep -q '//FollowingSeason("追番"),' "$FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV"
grep -q '//ToView("稍后看");' "$FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV"
echo "[DEBUG] 处理完成: TopNav.kt（修改验证通过）"

# 配合隐藏导航标签的修改（perl多行替换）
FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/HomeContent.kt"
echo -e "\n[DEBUG] 处理文件: $FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
if [ ! -f "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT" ]; then
  echo "ERROR: 文件不存在!"
  exit 1
fi
perl -i -0777 -pe '
  s{                HomeTopNavItem\.FollowingSeason -> \{
//                    if \(followingSeasonViewModel\.followingSeasons\.isEmpty\(\) && userViewModel\.isLogin\) \{
//                        followingSeasonViewModel\.loadMore\(\)
//                    \}
                \}}{//                HomeTopNavItem.FollowingSeason -> {
//                    if (followingSeasonViewModel.followingSeasons.isEmpty() && userViewModel.isLogin) {
//                        followingSeasonViewModel.loadMore()
//                    }
//                }}sg;
  s{                HomeTopNavItem\.ToView -> \{
//                    if \(toViewViewModel\.histories\.isEmpty\(\) && userViewModel\.isLogin\) \{
//                        toViewViewModel\.update\(\)
//                    \}
                \}}{//                HomeTopNavItem.ToView -> {
//                    if (toViewViewModel.histories.isEmpty() && userViewModel.isLogin) {
//                        toViewViewModel.update()
//                    }
//                }}sg;
  s{                        HomeTopNavItem\.FollowingSeason -> \{
                            if \(userViewModel\.isLogin\) \{
                                followingSeasonViewModel\.clearData\(\)
                                followingSeasonViewModel\.loadMore\(\)
                            \}
                        \}}{//                        HomeTopNavItem.FollowingSeason -> {
//                            if (userViewModel.isLogin) {
//                                followingSeasonViewModel.clearData()
//                                followingSeasonViewModel.loadMore()
//                            }
//                        }}sg;
  s{                        HomeTopNavItem\.ToView -> \{
                            if \(userViewModel\.isLogin\) \{
                                toViewViewModel\.clearData\(\)
                                toViewViewModel\.update\(\)
                            \}
                        \}}{//                        HomeTopNavItem.ToView -> {
//                            if (userViewModel.isLogin) {
//                                toViewViewModel.clearData()
//                                toViewViewModel.update()
//                            }
//                        }}sg;
  s{                    HomeTopNavItem\.FollowingSeason -> \{
                        if \(userViewModel\.isLogin\) \{
                            FollowingSeasonScreen\(showPageTitle = false\)
                        \} else \{
                            LoginRequiredScreen\(\)
                        \}
                    \}}{//                    HomeTopNavItem.FollowingSeason -> {
//                        if (userViewModel.isLogin) {
//                            FollowingSeasonScreen(showPageTitle = false)
//                        } else {
//                            LoginRequiredScreen()
//                        }
//                    }}sg;
  s{                    HomeTopNavItem\.ToView -> \{
                        if \(userViewModel\.isLogin\) \{
                            ToViewScreen\(showPageTitle = false\)
                        \} else \{
                            LoginRequiredScreen\(\)
                        \}
                    \}}{//                    HomeTopNavItem.ToView -> {
//                        if (userViewModel.isLogin) {
//                            ToViewScreen(showPageTitle = false)
//                        } else {
//                            LoginRequiredScreen()
//                        }
//                    }}sg;
' "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
# 新增：验证perl多行替换结果
echo "[DEBUG] 验证 HomeContent.kt perl多行替换结果..."
grep -q '//                HomeTopNavItem.FollowingSeason -> {' "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
grep -q '//                HomeTopNavItem.ToView -> {' "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
echo "[DEBUG] 处理完成: HomeContent.kt（perl替换验证通过）"

# 补充注释剩余两行
echo -e "\n[DEBUG] 补充处理 HomeContent.kt 剩余行"
sed -i \
  -e 's/^\([[:space:]]*\)HomeTopNavItem\.FollowingSeason -> followingSeasonState$/\1\/\/HomeTopNavItem.FollowingSeason -> followingSeasonState/' \
  -e 's/^\([[:space:]]*\)HomeTopNavItem\.ToView -> toViewState$/\1\/\/HomeTopNavItem.ToView -> toViewState/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
# 新增：验证剩余行注释结果
echo "[DEBUG] 验证 HomeContent.kt 剩余行注释结果..."
grep -q '//HomeTopNavItem.FollowingSeason -> followingSeasonState' "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
grep -q '//HomeTopNavItem.ToView -> toViewState' "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
echo "[DEBUG] 处理完成: HomeContent.kt（剩余行注释验证通过）"

echo -e "\n====================================="
echo "        所有脚本处理完成！所有修改验证通过！"
echo -e "====================================="
