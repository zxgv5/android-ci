#!/bin/bash
# customize-bv-frost819.sh

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
    print "    x5(0, R.string.play_speed_x5, 5f),"
    print "    x4_75(0, R.string.play_speed_x4_75, 4.75f),"
    print "    x4_5(3, R.string.play_speed_x4_5, 4.5f),"
    print "    x4_25(2, R.string.play_speed_x4_25, 4.25f),"
    print "    x4(0, R.string.play_speed_x4, 4f),"
    print "    x3_75(0, R.string.play_speed_x3_75, 3.75f),"
    print "    x3_5(3, R.string.play_speed_x3_5, 3.5f),"
    print "    x3_25(2, R.string.play_speed_x3_25, 3.25f),"
    print "    x3(0, R.string.play_speed_x3, 3f),"
    print "    x2_75(0, R.string.play_speed_x2_75, 2.75f),"
    print "    x2_5(0, R.string.play_speed_x2_2, 2.5f),"
    print "    x2_25(0, R.string.play_speed_x2_25, 2.25f),"
    print "    x2(4, R.string.play_speed_x2, 2f),"
    print "    x1_75(0, R.string.play_speed_x1_75, 1.75f),"
    print "    x1_5(3, R.string.play_speed_x1_5, 1.5f),"
    print "    x1_25(2, R.string.play_speed_x1_25, 1.25f),"
    print "    x1(1, R.string.play_speed_x1, 1f),"
    print "    x0_75(0, R.string.play_speed_x0_75, 0.75f),"
    print "    x0_5(0, R.string.play_speed_x0_5, 0.5f),"
    print "    x0_25(0, R.string.play_speed_x0_25, 0.25f);"
    # 跳过原来的5行枚举项
    for (i=0; i<6; i++) getline
    next
}
1' "$FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU" > "${FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU}.tmp" && mv "${FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU}.tmp" "$FROST819_BV_SOURCE_ASMKDABCCP_PLAYSPEEDMENU"
