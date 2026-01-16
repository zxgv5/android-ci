#!/bin/bash
# customize-bv-fantasy.sh
 
set -e  # 遇到错误立即退出，避免ci静默失败
 
FANTASY_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/fantasy-bv-source"
 
# 修改 AppConfiguration.kt 中的配置项
# 版本号规则调整，避免负数
# 修改包名
 
FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION="$FANTASY_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
sed -i \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
  -e 's/const val applicationId = "dev.aaa1115910.bv2"/const val applicationId = "dev.fantasy.bv"/' \
  "$FANTASY_BV_SOURCE_BSMK_APPCONFIGURATION"
 
# 修改应用名
FANTASY_BV_SOURCE_ASSDRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/debug/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV Debug.*<\/string>/<string name="app_name">fantasy Debug<\/string>/' "$FANTASY_BV_SOURCE_ASSDRV_STRINGS"
 
FANTASY_BV_SOURCE_ASSMRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/main/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV.*<\/string>/<string name="app_name">fantasy<\/string>/' "$FANTASY_BV_SOURCE_ASSMRV_STRINGS"
 
FANTASY_BV_SOURCE_ASSRRV_STRINGS="$FANTASY_BV_SOURCE_ROOT/app/shared/src/r8Test/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV R8 Test.*<\/string>/<string name="app_name">fantasy R8 Test<\/string>/' "$FANTASY_BV_SOURCE_ASSRRV_STRINGS"
 
# 尝试使用python修复“动态”页长按下方向键焦点左移出区问题
# 需要对如下四个文件进行修改
# /gradle/libs.versions.toml、/app/build.gradle.kts、/app/tv/build.gradle.kts 和 /app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt
# FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
# CI_CUSTOMIZE_SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT="$CI_CUSTOMIZE_SCRIPTS_DIR/modify_bv_fantasy_dynamics_screen.py"
# echo "尝试使用python修复“动态”页长按下方向键焦点左移出区问题"
# python3 "$FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN_PYTHON_SCRIPT" "$FANTASY_BV_SOURCE_ROOT"
# 5. 校验python脚本执行结果
# if [ $? -eq 0 ]; then
#     echo "python脚本执行成功"
# else
#     echo "python脚本执行失败！"
#     exit 1
# fi

# 尝试使用python修复“动态”页长按下方向键焦点左移出区问题
FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
CI_FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN="$GITHUB_WORKSPACE/ci_source/patches/bv_fantasy/ci_DynamicsScreen.kt"
if [ ! -f "$CI_FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN" ]; then
    echo "❌ 错误：源文件 $CI_FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN 不存在"
    exit 1
fi
cp -f "$CI_FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN" "$FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN"

FANTASY_BV_SOURCE_ASSMKDABVH_DYNAMICVIEWMODEL="$FANTASY_BV_SOURCE_ROOT/app/shared/src/main/kotlin/dev/aaa1115910/bv/viewmodel/home/DynamicViewModel.kt"
CI_FANTASY_BV_SOURCE_ASSMKDABVH_DYNAMICVIEWMODEL="$GITHUB_WORKSPACE/ci_source/patches/bv_fantasy/ci_DynamicViewModel.kt"
if [ ! -f "$CI_FANTASY_BV_SOURCE_ASSMKDABVH_DYNAMICVIEWMODEL" ]; then
    echo "❌ 错误：源文件 $CI_FANTASY_BV_SOURCE_ASSMKDABVH_DYNAMICVIEWMODEL 不存在"
    exit 1
fi
cp -f "$CI_FANTASY_BV_SOURCE_ASSMKDABVH_DYNAMICVIEWMODEL" "$FANTASY_BV_SOURCE_ASSMKDABVH_DYNAMICVIEWMODEL"

FANTASY_BV_SOURCE_ATSMKDABTCV_SMALLVIDEOCARD="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/videocard/SmallVideoCard.kt"
CI_FANTASY_BV_SOURCE_ATSMKDABTCV_SMALLVIDEOCARD="$GITHUB_WORKSPACE/ci_source/patches/bv_fantasy/ci_SmallVideoCard.kt"
if [ ! -f "$CI_FANTASY_BV_SOURCE_ATSMKDABTCV_SMALLVIDEOCARD" ]; then
    echo "❌ 错误：源文件 $CI_FANTASY_BV_SOURCE_ATSMKDABTCV_SMALLVIDEOCARD 不存在"
    exit 1
fi
cp -f "$CI_FANTASY_BV_SOURCE_ATSMKDABTCV_SMALLVIDEOCARD" "$_FANTASY_BV_SOURCE_ATSMKDABTCV_SMALLVIDEOCARD"
# 结束尝试使用python修复“动态”页长按下方向键焦点左移出区问题

# if [ -f "$FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN" ] && cmp -s "$CI_FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN" "$FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN"; then
#     echo "🎉 成功：用 $CI_FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN 覆盖 $FANTASY_BV_SOURCE_ATSMKDABTSMH_DYNAMICSSCREEN"
# else
#     echo "❌ 失败：文件覆盖未生效"
#     exit 1
# fi
 
# TV端倍速范围调整
# 使用sed的上下文匹配，确保只修改VideoPlayerPictureMenuItem.PlaySpeed相关的行
FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/playermenu/PictureMenu.kt"
sed -i '/VideoPlayerPictureMenuItem\.PlaySpeed ->/,/^[[:space:]]*)/s/range = 0\.25f\.\.3f/range = 0.25f..5f/' "$FANTASY_BV_SOURCE_PTSMKDABPTCP_PICTUREMENU"
 
# 焦点逻辑更改，首先落到弹幕库上
FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO="$FANTASY_BV_SOURCE_ROOT/player/tv/src/main/kotlin/dev/aaa1115910/bv/player/tv/controller/ControllerVideoInfo.kt"
# 使用捕获组保留原缩进
sed -i 's/^\([[:space:]]*\)down = focusRequesters\[if (showNextVideoBtn) "nextVideo" else "speed"\] ?: FocusRequester()/\1down = focusRequesters["danmaku"] ?: FocusRequester()/' "$FANTASY_BV_SOURCE_PTSMKDABPTC_CONTROLLERVIDEOINFO"
 
# 隐藏左边 搜索、UGC和PGC 三个侧边栏页面
FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/DrawerContent.kt"
sed -i \
  -e 's/^\([[:space:]]*\)DrawerItem\.Search,/\1\/\/DrawerItem.Search,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.UGC,/\1\/\/DrawerItem.UGC,/' \
  -e 's/^\([[:space:]]*\)DrawerItem\.PGC,/\1\/\/DrawerItem.PGC,/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_DRAWERCONTENT"
 
# 隐藏顶上 追番 、 稍后看 两个导航标签
FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/component/TopNav.kt"
sed -i \
  -e 's/^\([[:space:]]*\)Favorite("收藏"),[[:space:]]*$/\1Favorite("收藏");/' \
  -e 's/^\([[:space:]]*\)FollowingSeason("追番"),[[:space:]]*$/\/\/\1FollowingSeason("追番"),/' \
  -e 's/^\([[:space:]]*\)ToView("稍后看");[[:space:]]*$/\/\/\1ToView("稍后看");/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTC_TOPNAV"
 
# 配合上面隐藏两个导航标签的修改
FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/HomeContent.kt"
# 使用perl一次性处理6个多行替换 
perl -i -0777 -pe '
  # 1. 替换第一个FollowingSeason代码块（已有部分注释）
  s{                HomeTopNavItem\.FollowingSeason -> \{
//                    if \(followingSeasonViewModel\.followingSeasons\.isEmpty\(\) && userViewModel\.isLogin\) \{
//                        followingSeasonViewModel\.loadMore\(\)
//                    \}
                \}}{//                HomeTopNavItem.FollowingSeason -> {
//                    if (followingSeasonViewModel.followingSeasons.isEmpty() && userViewModel.isLogin) {
//                        followingSeasonViewModel.loadMore()
//                    }
//                }}sg;
  
  # 2. 替换第一个ToView代码块（已有部分注释）
  s{                HomeTopNavItem\.ToView -> \{
//                    if \(toViewViewModel\.histories\.isEmpty\(\) && userViewModel\.isLogin\) \{
//                        toViewViewModel\.update\(\)
//                    \}
                \}}{//                HomeTopNavItem.ToView -> {
//                    if (toViewViewModel.histories.isEmpty() && userViewModel.isLogin) {
//                        toViewViewModel.update()
//                    }
//                }}sg;
  
  # 3. 替换第二个FollowingSeason代码块（完全无注释）
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
  
  # 4. 替换第二个ToView代码块（完全无注释）
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
  
  # 5. 替换第三个FollowingSeason代码块（屏幕渲染部分）
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
  
  # 6. 替换第三个ToView代码块（屏幕渲染部分）
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
 
# 还有两行没有注释掉，补上
sed -i \
  -e 's/^\([[:space:]]*\)HomeTopNavItem\.FollowingSeason -> followingSeasonState$/\1\/\/HomeTopNavItem.FollowingSeason -> followingSeasonState/' \
  -e 's/^\([[:space:]]*\)HomeTopNavItem\.ToView -> toViewState$/\1\/\/HomeTopNavItem.ToView -> toViewState/' \
  "$FANTASY_BV_SOURCE_ATSMKDABTSM_HOMECONTENT"