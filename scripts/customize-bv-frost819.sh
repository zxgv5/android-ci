#!/bin/bash
# customize-bv-frost819.sh

set -e  # 遇到错误立即退出，避免CI静默失败

FROST819_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/frost819-bv-source"
 
# 修改 AppConfiguration.kt 中的配置项
# 版本号规则调整，避免负数
# 修改包名
# 修改sdk的最低版本为23，避免和其他库的链接问题
FROST819_BV_SOURCE_BSMK_APPCONFIGURATION="$FROST819_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
# 修改 AppConfiguration.kt 中的配置项
sed -i \
  -e 's/const val minSdk = 21/const val minSdk = 23/' \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
  -e 's/const val applicationId = "dev.frost819.bv"/const val applicationId = "dev.f819.bv"/' \
  "$FROST819_BV_SOURCE_BSMK_APPCONFIGURATION"
 
# 修改应用名
FROST819_BV_SOURCE_ASDRV_STRINGS="$FROST819_BV_SOURCE_ROOT/app/src/debug/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV Debug.*<\/string>/<string name="app_name">f819 Debug<\/string>/' "$FROST819_BV_SOURCE_ASDRV_STRINGS"
 
FROST819_BV_SOURCE_ASMRV_STRINGS="$FROST819_BV_SOURCE_ROOT/app/src/main/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV.*<\/string>/<string name="app_name">f819<\/string>/' "$FROST819_BV_SOURCE_ASMRV_STRINGS"
 
FROST819_BV_SOURCE_ASRRV_STRINGS="$FROST819_BV_SOURCE_ROOT/app/src/r8Test/res/values/strings.xml"
sed -i 's/<string[[:space:]]*name="app_name"[[:space:]]*>.*BV R8 Test.*<\/string>/<string name="app_name">f819 R8 Test<\/string>/' "$FROST819_BV_SOURCE_ASRRV_STRINGS"
 
# 修改倍速设置
FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU="$FROST819_BV_SOURCE_ROOT/app/src/main/kotlin/dev/aaa1115910/bv/component/controllers/playermenu/PlaySpeedMenu.kt"
# 使用awk或sed重新构建文件
awk '
/enum class PlaySpeedItem\(val code: Int, private val strRes: Int, val speed: Float\) \{/ {
    print $0
    print "    x2(4, R.string.play_speed_x2, 2f),"
    print "    x1_75(6, R.string.play_speed_x1_75, 1.75f),"
    print "    x1_5(3, R.string.play_speed_x1_5, 1.5f),"
    print "    x1_25(2, R.string.play_speed_x1_25, 1.25f),"
    print "    x1(1, R.string.play_speed_x1, 1f),"
    print "    x0_75(5, R.string.play_speed_x0_75, 0.75f),"
    print "    x0_5(0, R.string.play_speed_x0_5, 0.5f);"
    # 跳过原来的5行枚举项
    for (i=0; i<6; i++) getline
    next
}
1' "$FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU" > "${FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU}.tmp" && mv "${FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU}.tmp" "$FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU"
 
# 配合倍速设置修改
# FROST819_BV_SOURCE_ASMRV_STRINGS="$FROST819_BV_SOURCE_ROOT/app/src/main/res/values/strings.xml"
# 使用awk处理：找到包含播放速度字符串的区域，然后替换
awk '
# 定义新的播放速度字符串数组
BEGIN {
    new_strings[1] = "    <string name=\"play_speed_x0_5\">0.5</string>"
    new_strings[2] = "    <string name=\"play_speed_x0_75\">0.75</string>"
    new_strings[3] = "    <string name=\"play_speed_x1\">1.0</string>"
    new_strings[4] = "    <string name=\"play_speed_x1_25\">1.25</string>"
    new_strings[5] = "    <string name=\"play_speed_x1_5\">1.5</string>"
    new_strings[6] = "    <string name=\"play_speed_x1_75\">1.75</string>"
    new_strings[7] = "    <string name=\"play_speed_x2\">2.0</string>"
    in_play_speed_block = 0
    play_speed_printed = 0
}
 
# 检测到第一个播放速度字符串时，开始标记块
/play_speed_x0_5/ {
    in_play_speed_block = 1
    # 不打印原有的播放速度字符串，直接打印新的
    for (i=1; i<=20; i++) {
        print new_strings[i]
    }
    # 在播放速度字符串后添加一个空行
    print ""
    play_speed_printed = 1
    next
}
 
# 如果在播放速度块中，跳过其他原有的播放速度字符串
in_play_speed_block && /play_speed_x[0-9]/ {
    next
}
 
# 如果遇到其他字符串，结束播放速度块标记
/^    <string name="[^"]*">/ && !/play_speed/ {
    in_play_speed_block = 0
}
 
# 打印其他所有行
{
    if (!in_play_speed_block) {
        print $0
    }
}
 
END {
    # 如果文件中没有任何播放速度字符串，在文件末尾添加
    if (!play_speed_printed) {
        for (i=1; i<=20; i++) {
            print new_strings[i]
        }
        # 在播放速度字符串后添加一个空行
        print ""
    }
}
' "$FROST819_BV_SOURCE_ASMRV_STRINGS" > "${FROST819_BV_SOURCE_ASMRV_STRINGS}.tmp" && mv "${FROST819_BV_SOURCE_ASMRV_STRINGS}.tmp" "$FROST819_BV_SOURCE_ASMRV_STRINGS"