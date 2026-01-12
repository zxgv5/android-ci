#!/bin/bash
# customize-vlc.sh

set -e  # 遇到错误立即退出，避免CI静默失败

# 尝试解决libvlc中vlc内核代码在http的user agent中添加"LibVLC/xxx"独特字段的问题
# 该独特字段可能被b站block

VLC_SOURCE_ROOT="$GITHUB_WORKSPACE/vlc-android-source/libvlcjni/vlc"

VLC_SOURCE_LIB_COREC="$VLC_SOURCE_ROOT/lib/core.c"
VLC_SOURCE_SRC_LIBVLCC="$VLC_SOURCE_ROOT/src/libvlc.c"
VLC_SOURCE_MODULES_ACCESS_LIVE555CPP="$VLC_SOURCE_ROOT/modules/access/live555.cpp"

# 修改 core.c 中的字符串（更精确的匹配）
# 原行：     && (asprintf (&str, "%s LibVLC/"PACKAGE_VERSION, http) != -1))
# 目标：     && (asprintf (&str, "%s abc_media_editor", http) != -1))
sed -i 's/asprintf (\&str, "%s LibVLC\/"PACKAGE_VERSION, http) != -1/asprintf (\&str, "%s abc_media_editor", http) != -1/' "$VLC_SOURCE_LIB_COREC"

# 修改 libvlc.c 中的第一处字符串
# 原行：                   "VLC media player (LibVLC "VERSION")" );
# 目标：                   "abc media editor" );
sed -i 's/"VLC media player (LibVLC "VERSION")" );/"abc media editor" );/' "$VLC_SOURCE_SRC_LIBVLCC"

# 修改 libvlc.c 中的第二处字符串  
# 原行：                   "VLC/"PACKAGE_VERSION" LibVLC/"PACKAGE_VERSION );
# 目标：                   "abc/abc_media_editor/");
sed -i 's/"VLC\/"PACKAGE_VERSION" LibVLC\/"PACKAGE_VERSION );/"abc\/abc_media_editor\/");/' "$VLC_SOURCE_SRC_LIBVLCC"

# 修改 live555.cpp 中的字符串
# 原行：                                     "LibVLC/" VERSION, i_http_port, p_sys );
# 目标：                                     "abc_media_editor", i_http_port, p_sys );
sed -i 's/"LibVLC\/" VERSION, i_http_port, p_sys );/"abc_media_editor", i_http_port, p_sys );/' "$VLC_SOURCE_MODULES_ACCESS_LIVE555CPP"

