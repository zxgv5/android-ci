#!/bin/bash
# customize-bv-fantasy.sh
set -e

FANTASY_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/fantasy-bv-source"

# ========== 1. 修改 AppConfiguration.kt ==========
FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION="$FANTASY_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
sed -i \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
  -e 's/const val applicationId = "dev.aaa1115910.bv2"/const val applicationId = "dev.fantasy.bv"/' \
  "$FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION"
echo "[1/10] AppConfiguration.kt 修改完成"

# ========== 2. 修改应用名 ==========
# debug
FANTASY_BV_SOURCE_ASSDRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/debug/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV Debug.*<\/string>/<string name="app_name">fantasy Debug<\/string>/' "$FANTASY_BV_SOURCE_ASSDRV_STRINGS"
# main
FANTASY_BV_SOURCE_ASSMRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/main/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV.*<\/string>/<string name="app_name">fantasy<\/string>/' "$FANTASY_BV_SOURCE_ASSMRV_STRINGS"
# r8Test
FANTASY_BV_SOURCE_ASSRRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/r8Test/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV R8 Test.*<\/string>/<string name="app_name">fantasy R8 Test<\/string>/' "$FANTASY_BV_SOURCE_ASSRRV_STRINGS"
echo "[2/10] 应用名修改完成"

# ========== 3. Python 处理 DynamicsScreen.kt ==========
FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
CI_CUSTOMIZE_SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT="$CI_CUSTOMIZE_SCRIPTS_DIR/modify_bv_fantasy_dynamics_screen.py"

if ! command -v python3 &> /dev/null; then
    echo "错误：未找到python3！"
    exit 1
fi
if [ ! -f "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT" ] || [ ! -f "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN" ]; then
    echo "错误：Python脚本或目标文件不存在！"
    exit 1
fi
python3 "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT" "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"
if [ $? -ne 0 ]; then
    echo "错误：Python脚本执行失败！"
    exit 1
fi
echo "[3/10] DynamicsScreen.kt 修改完成"

# ========== 4. 核心修正：libs.versions.toml（版本号改为1.0.0） ==========
FANTASY_BV_SOURCE_GRADLE_LVT="$FANTASY_BV_SOURCE_ROOT/gradle/libs.versions.toml"
if [ ! -f "$FANTASY_BV_SOURCE_GRADLE_LVT" ]; then
    echo "错误：libs.versions.toml 文件不存在！"
    exit 1
fi

# 4.1 追加版本变量到 [versions] 块末尾（关键：版本改为1.0.0）
sed -i '/^\[versions\]/a\androidxComposeBom = "2025.12.00"\nandroidxTvFoundation = "1.0.0"' "$FANTASY_BV_SOURCE_GRADLE_LVT"
# 4.2 追加依赖库条目到 [libraries] 块末尾
sed -i '/^\[libraries\]/a\androidx-compose-bom = { module = "androidx.compose:compose-bom", version.ref = "androidxComposeBom" }\nandroidx-tv-foundation = { module = "androidx.tv:tv-foundation", version.ref = "androidxTvFoundation" }' "$FANTASY_BV_SOURCE_GRADLE_LVT"
echo "[4/10] libs.versions.toml 配置完成（版本修正为1.0.0）"

# ========== 5. 修正 player/tv/build.gradle.kts ==========
FANTASY_BV_SOURCE_PT_BGK="$FANTASY_BV_SOURCE_ROOT/player/tv/build.gradle.kts"
if [ ! -f "$FANTASY_BV_SOURCE_PT_BGK" ]; then
    echo "错误：player/tv/build.gradle.kts 文件不存在！"
    exit 1
fi

# 5.1 在 dependencies 块首行添加 Compose BOM
sed -i '/dependencies {/a\    val composeBom = platform(libs.androidx.compose.bom)\n    implementation(composeBom)' "$FANTASY_BV_SOURCE_PT_BGK"
# 5.2 替换原有硬编码依赖为 libs 引用
sed -i 's/implementation(androidx.compose.tv.foundation)/implementation(libs.androidx.tv.foundation)/' "$FANTASY_BV_SOURCE_PT_BGK"
echo "[5/10] player/tv/build.gradle.kts 配置完成"

# ========== 6. TV端倍速调整 ==========
FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/playermenu/PictureMenu.kt"
sed -i '/VideoPlayerPictureMenuItem\.PlaySpeed ->/,/^[[:space:]]*)/s/range = 0\.25f\.\.3f/range = 0.25f..5f/' "$FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU"
echo "[6/10] PictureMenu.kt 倍速调整完成"

# ========== 7. 焦点逻辑修改 ==========
FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
sed -i 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' "$FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO"
echo "[7/10] ControllerVideoInfo.kt 焦点修改完成"

# ========== 8. 隐藏侧边栏 ==========
FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/DrawerContent.kt"
sed -i \
  -e 's/^\([[:space:]]*\)DrawerItem\.Search,/\1\/\/DrawerItem.Search,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.UGC,/\1\/\/DrawerItem.UGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.PGC,/\1\/\/DrawerItem.PGC,/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"
echo "[8/10] DrawerContent.kt 侧边栏隐藏完成"

# ========== 9. 隐藏顶部导航 ==========
FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/TopNav.kt"
sed -i \
  -e 's/^\([[:space:]]*\)Favorite("收藏"),[[:space:]]*$/\1Favorite("收藏");/' \
  -e 's/^\([[:space:]]*\)FollowingSeason("追番"),[[:space:]]*$/\/\/\1FollowingSeason("追番"),/' \
  -e 's/^\([[:space:]]*\)ToView("稍后看");[[:space:]]*$/\/\/\1ToView("稍后看");/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV"
echo "[9/10] TopNav.kt 导航隐藏完成"

# ========== 10. 修改 HomeContent.kt ==========
FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/HomeContent.kt"
if [ ! -f "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT" ]; then
    echo "错误：HomeContent.kt 文件不存在！"
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

# 补充注释剩余行
sed -i \
  -e 's/^\([[:space:]]*\)HomeTopNavItem\.FollowingSeason -> followingSeasonState$/\1\/\/HomeTopNavItem.FollowingSeason -> followingSeasonState/' \
  -e 's/^\([[:space:]]*\)HomeTopNavItem\.ToView -> toViewState$/\1\/\/HomeTopNavItem.ToView -> toViewState/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"
echo "[10/10] HomeContent.kt 修改完成"

echo "===== 所有脚本修改完成！版本号已修正为1.0.0 ====="