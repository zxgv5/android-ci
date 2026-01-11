#!/bin/bash
# customize-bv-fantasy.sh

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

# 尝试修复“动态”页面长按下方向键焦点左移出视频选择区的问题
# FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
# sed -i \
#   # 1. 在 onFocusChanged 导入后添加 TV 库的 FocusRestriction 正确导入
#   -e '/import androidx.compose.ui.focus.onFocusChanged/a\import androidx.tv.foundation.focus.FocusRestriction' \
#   # 2. 为 LazyVerticalGrid 的 modifier 添加 focusRestrict 修饰符
#   -e 's/modifier = modifier\.fillMaxSize()/modifier = modifier.fillMaxSize().focusRestrict(FocusRestriction.Scrollable)/' \
#   "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"
# sed -i \
#   # 1. 添加焦点请求器和列数常量导入/定义
#   -e '/import androidx.compose.runtime.rememberCoroutineScope/a\import androidx.compose.ui.focus.FocusRequester\nimport androidx.compose.ui.focus.focusRequester\nimport androidx.compose.ui.input.key.KeyDirectionLeft' \
#   -e '/val scope = rememberCoroutineScope()/a\    val gridFocusRequester = remember { FocusRequester() }\n    val gridColumns = 4 // Grid的固定列数' \
#   # 2. 增强onPreviewKeyEvent：拦截左方向键+锁定焦点
#   -e '/onPreviewKeyEvent {/a\        // 拦截左方向键，阻止焦点向左逃逸到侧边栏\n        if(it.type == KeyEventType.KeyDown && it.key == KeyDirectionLeft) {\n            // 计算当前焦点项所在列：index % 列数 == 0 表示第一列\n            val isFirstColumn = currentFocusedIndex >= 0 && (currentFocusedIndex % gridColumns) == 0\n            if(isFirstColumn) {\n                // 第一列时强制保留焦点在Grid内\n                gridFocusRequester.requestFocus()\n                return@onPreviewKeyEvent true\n            }\n        }\n        // 强制焦点始终留在Grid（防止快速滚动时焦点丢失）\n        if(!lazyGridState.isScrollInProgress && it.type == KeyEventType.KeyUp) {\n            gridFocusRequester.requestFocus()\n        }' \
#   # 3. 给Grid添加focusRequester，确保焦点锁定
#   -e 's/\.focusRestrict(FocusRestriction.Scrollable)/\.focusRestrict(FocusRestriction.Scrollable).focusRequester(gridFocusRequester)/' \
#   "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"
# sed -i \
#   -e '/ProvideListBringIntoViewSpec {/a\    Box(modifier = Modifier.focusRequester(gridFocusRequester).focusable()) {' \
#   -e '/ProvideListBringIntoViewSpec {/!b' -e ':a' -e 'N' -e '/        }\n    } else {/!ba' -e 's/\n        }/\n        }\n    }/' \
#   "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"

# 尝试修复“动态”页面长按下方向键焦点左移出视频选择区的问题
# ========== 整合后的 DynamicsScreen.kt 完整修改逻辑 ==========
FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN="$FANTASY_BV_SOURCE_ROOT/app/tv/src/main/kotlin/dev/aaa1115910/bv/tv/screens/main/home/DynamicsScreen.kt"
sed -i \
  # 1. 基础：添加 FocusRestriction 导入（原第一部分脚本）
  -e '/import androidx.compose.ui.focus.onFocusChanged/a\import androidx.tv.foundation.focus.FocusRestriction' \
  # 2. 基础：给 Grid 加 focusRestrict 修饰符（原第一部分脚本）
  -e 's/modifier = modifier\.fillMaxSize()/modifier = modifier.fillMaxSize().focusRestrict(FocusRestriction.Scrollable)/' \
  # 3. 补全：添加所有焦点相关导入（含原第二部分漏的 focusRequester 修饰符）
  -e '/import androidx.tv.foundation.focus.FocusRestriction/a\import androidx.compose.ui.focus.FocusRequester\nimport androidx.compose.ui.focus.focusRequester\nimport androidx.compose.ui.input.key.KeyDirectionLeft' \
  # 4. 核心：定义焦点变量（修正位置，确保使用前初始化）
  -e '/val scope = rememberCoroutineScope()/a\    val gridFocusRequester = remember { FocusRequester() }\n    val gridColumns = 4 // Grid固定列数' \
  # 5. 核心：增强 onPreviewKeyEvent 拦截左方向键（原第二部分脚本）
  -e '/onPreviewKeyEvent {/a\        // 拦截左方向键，阻止焦点向左逃逸到侧边栏\n        if(it.type == KeyEventType.KeyDown && it.key == KeyDirectionLeft) {\n            // 计算当前焦点项所在列：index % 列数 == 0 表示第一列\n            val isFirstColumn = currentFocusedIndex >= 0 && (currentFocusedIndex % gridColumns) == 0\n            if(isFirstColumn) {\n                // 第一列时强制保留焦点在Grid内\n                gridFocusRequester.requestFocus()\n                return@onPreviewKeyEvent true\n            }\n        }\n        // 强制焦点始终留在Grid（防止快速滚动时焦点丢失）\n        if(!lazyGridState.isScrollInProgress && it.type == KeyEventType.KeyUp) {\n            gridFocusRequester.requestFocus()\n        }' \
  # 6. 核心：给 Grid 绑定 focusRequester（修复编译报错）
  -e 's/\.focusRestrict(FocusRestriction.Scrollable)/\.focusRestrict(FocusRestriction.Scrollable).focusRequester(gridFocusRequester)/' \
  # 7. 可选：外层 Box 加焦点容器（原第三部分脚本，增强稳定性）
  -e '/ProvideListBringIntoViewSpec {/a\    Box(modifier = Modifier.focusRequester(gridFocusRequester).focusable()) {' \
  -e '/ProvideListBringIntoViewSpec {/!b' -e ':a' -e 'N' -e '/        }\n    } else {/!ba' -e 's/\n        }/\n        }\n    }/' \
  "$FANTASY_BV_SOURCE_PTSMKDABPTCP_ATSMKDABTSMH_DYNAMICSSCREEN"

FANTASY_BV_SOURCE_GRADLE_LVT="$FANTASY_BV_SOURCE_ROOT/gradle/libs.versions.toml"
sed -i \
  # 在 [versions] 末尾添加 Compose BOM 和 TV 库版本
  -e '/zxing = "3.5.3"/a\androidxComposeBom = "2025.12.00"\nandroidxTvFoundation = "1.1.0"' \
  # 在 [libraries] 末尾添加对应库映射
  -e '/zxing = { module = "com.google.zxing:core", version.ref = "zxing" }/a\\n# Compose BOM\androidx-compose-bom = { module = "androidx.compose:compose-bom", version.ref = "androidxComposeBom" }\n# AndroidX TV Foundation\androidx-tv-foundation = { module = "androidx.tv:tv-foundation", version.ref = "androidxTvFoundation" }' \
  "$FANTASY_BV_SOURCE_GRADLE_LVT"

FANTASY_BV_SOURCE_PT_BGK="$FANTASY_BV_SOURCE_ROOT/player/tv/build.gradle.kts"
sed -i \
  # 1. 在 dependencies 开头添加 Compose BOM 依赖
  -e '/dependencies {/a\    val composeBom = platform(libs.androidx.compose.bom)\n    implementation(composeBom)\n    androidTestImplementation(composeBom)' \
  # 2. 替换硬编码的 tv-foundation 依赖为 libs 引用
  -e 's/implementation(androidx.compose.tv.foundation)/implementation(libs.androidx.tv.foundation)/' \
  "$FANTASY_BV_SOURCE_PT_BGK"

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
