#!/bin/bash

# CI 文件工具函数库
# 用法：在脚本中 source 此文件即可使用其中的函数

# =====================================================================
# 函数：ci_source_patch
# 描述：复制补丁文件到源文件
# 参数：
#   $1 - src_dir: 源文件目录
#   $2 - src_name: 源文件名
#   $3 - patch_dir: 补丁文件目录
# =====================================================================
ci_source_patch() {
    # 检查参数数量
    if [ $# -ne 3 ]; then
        echo "Error: ci_source_patch requires 3 arguments" >&2
        echo "Usage: ci_source_patch src_dir src_name patch_dir" >&2
        return 1
    fi
    
    # 提取参数
    local src_dir="$1"
    local src_name="$2"
    local patch_dir="$3"
    
    # 构建路径
    local patched="${patch_dir}/ci_${src_name}"
    local source_file="${src_dir}/${src_name}"
    
    # 检查源补丁文件是否存在
    if [ ! -f "$patched" ]; then
        echo "Error: Source patch file does not exist: $patched" >&2
        return 1
    fi
    
    # 检查目标目录是否存在
    if [ ! -d "$src_dir" ]; then
        echo "Error: Destination directory does not exist: $src_dir" >&2
        return 1
    fi
    
    # 显示调试信息
    echo "Patching file: $source_file"
    echo "  Using patch: $patched"
    
    # 执行复制操作
    cp -f "$patched" "$source_file"
    
    # 检查操作是否成功
    if [ $? -eq 0 ]; then
        echo "  ? Successfully patched: $src_name"
    else
        echo "  ? Failed to patch: $src_name" >&2
        return 1
    fi
}

# =====================================================================
# 可选：添加其他相关函数
# =====================================================================

# 函数：ci_check_patch_exists
# 描述：检查补丁文件是否存在
ci_check_patch_exists() {
    if [ $# -ne 2 ]; then
        echo "Usage: ci_check_patch_exists src_name patch_dir" >&2
        return 1
    fi
    
    local src_name="$1"
    local patch_dir="$2"
    local patch_file="${patch_dir}/ci_${src_name}"
    
    if [ -f "$patch_file" ]; then
        echo "Patch exists: $patch_file"
        return 0
    else
        echo "Patch not found: $patch_file" >&2
        return 1
    fi
}

# 函数：ci_backup_source_file
# 描述：备份源文件
ci_backup_source_file() {
    if [ $# -ne 2 ]; then
        echo "Usage: ci_backup_source_file src_dir src_name" >&2
        return 1
    fi
    
    local src_dir="$1"
    local src_name="$2"
    local source_file="${src_dir}/${src_name}"
    local backup_file="${source_file}.backup.$(date +%Y%m%d%H%M%S)"
    
    if [ -f "$source_file" ]; then
        cp "$source_file" "$backup_file"
        echo "Backup created: $backup_file"
        return 0
    else
        echo "Source file not found: $source_file" >&2
        return 1
    fi
}