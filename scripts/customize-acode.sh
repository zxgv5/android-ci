#!/bin/bash
# customize-acode.sh

set -e  # 遇到错误立即退出，避免CI静默失败

# 尝试解决libvlc中vlc内核代码在http的user agent中添加"LibVLC/xxx"独特字段的问题
# 该独特字段可能被b站block

ACODE_SOURCE_ROOT="$GITHUB_WORKSPACE/acode_source"

ACODE_SOURCE_BUILD_EXTRAS_GRADLE="$ACODE_SOURCE_ROOT/build-extras.gradle"
CI_ACODE_SOURCE_BUILD_EXTRAS_GRADLE="$GITHUB_WORKSPACE/ci_source/patches/acode/ci_build-extras.gradle"
if [ ! -f "$CI_ACODE_SOURCE_BUILD_EXTRAS_GRADLE" ]; then
    echo "❌ 错误：源文件 $CI_ACODE_SOURCE_BUILD_EXTRAS_GRADLE 不存在"
    exit 1
fi
cp -f "$CI_ACODE_SOURCE_BUILD_EXTRAS_GRADLE" "$ACODE_SOURCE_BUILD_EXTRAS_GRADLE"
