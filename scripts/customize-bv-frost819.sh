#!/bin/bash
# customize-bv-frost819.sh

FROST819_BV_SOURCE_ROOT="$GITHUB_WORKSPACE/frost819-bv-source"

FROST819_BV_SOURCE_APPCONFIGURATION="$FROST819_BV_SOURCE_ROOT/buildSrc/src/main/kotlin/AppConfiguration.kt"
# 修改 AppConfiguration.kt 中的两个配置项
sed -i \
  -e 's/const val minSdk = 21/const val minSdk = 23/' \
  -e 's/"git rev-list --count HEAD".exec().toInt() - 5/"git rev-list --count HEAD".exec().toInt() + 1/' \
  "$FROST819_BV_SOURCE_APPCONFIGURATION"