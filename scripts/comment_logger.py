#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
注释日志工具
用于注释掉Kotlin项目中特定的日志相关代码，并将logger方法调用替换为空操作
"""

import os
import re
import sys

def find_expression_end(lines, start_line_idx, start_col_idx):
    """
    找到logger表达式结束的位置
    返回结束行索引和结束列索引
    """
    line_idx = start_line_idx
    col_idx = start_col_idx
    line = lines[line_idx]
    
    # 找到logger方法调用的位置
    logger_methods = ['info', 'fInfo', 'warn', 'fWarn', 'error', 
                     'fError', 'exception', 'fException', 'debug', 'fDebug']
    
    # 检查当前位置是否在logger方法调用上
    for method in logger_methods:
        pattern = fr'logger\.{method}\b'
        match = re.search(pattern, line[col_idx:])
        if match:
            # 从匹配位置开始
            col_idx = col_idx + match.start()
            break
    
    # 向前查找非空白字符，确保我们不在字符串或注释中
    while col_idx < len(line) and line[col_idx].isspace():
        col_idx += 1
    
    # 从当前位置开始，查找整个表达式的结束
    # 记录括号和大括号的嵌套
    paren_count = 0
    brace_count = 0
    in_string = False
    string_char = None
    escape = False
    
    # 从当前行当前位置开始
    for i in range(line_idx, len(lines)):
        current_line = lines[i]
        start_pos = col_idx if i == line_idx else 0
        
        for j in range(start_pos, len(current_line)):
            char = current_line[j]
            
            if escape:
                escape = False
                continue
                
            if char == '\\':
                escape = True
                continue
                
            if not in_string:
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
                elif char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    # 当大括号计数归零且括号计数也归零时，表达式结束
                    if brace_count == 0 and paren_count == 0:
                        # 确保这不是一个空的大括号对
                        # 检查当前位置之后是否有内容
                        return i, j
                elif char in ('"', "'"):
                    in_string = True
                    string_char = char
            else:
                if char == string_char:
                    in_string = False
                    string_char = None
        
        # 如果到达行尾，重置列索引为下一行的开始
        col_idx = 0
    
    # 如果没有找到匹配的结束，返回最后的位置
    return len(lines) - 1, len(lines[-1]) - 1

def process_file(filepath):
    """
    处理单个文件
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        modified = False
        new_lines = []
        i = 0
        
        while i < len(lines):
            line = lines[i]
            
            # 检查是否需要注释整行（导入语句等）
            should_comment = False
            
            # 检查导入语句
            if re.search(r'^\s*import\s+io\.github\.oshai\.kotlinlogging\.KotlinLogging', line):
                should_comment = True
            elif re.search(r'^\s*import\s+dev\.aaa1115910\.bv\.util\.fInfo', line):
                should_comment = True
            elif re.search(r'\bKotlinLogging\.logger\s*\{', line):
                should_comment = True
            elif re.search(r'\blogger\s*\(\s*["\']BvVideoPlayer["\']\s*\)', line):
                should_comment = True
            elif re.search(r'\bandroidLogger\b', line):
                should_comment = True
            
            # 检查是否包含logger方法调用
            logger_methods = ['info', 'fInfo', 'warn', 'fWarn', 'error', 
                             'fError', 'exception', 'fException', 'debug', 'fDebug']
            
            has_logger_call = False
            for method in logger_methods:
                pattern = fr'\blogger\.{method}\b'
                if re.search(pattern, line):
                    has_logger_call = True
                    break
            
            if should_comment and not line.strip().startswith('//'):
                # 注释整行
                indent_match = re.match(r'^(\s*)', line)
                if indent_match:
                    indent = indent_match.group(1)
                    rest = line[len(indent):].rstrip('\n')
                    new_lines.append(indent + '//' + rest + '\n')
                else:
                    new_lines.append('//' + line)
                modified = True
                i += 1
            elif has_logger_call:
                # 找到logger调用的开始位置
                match = None
                for method in logger_methods:
                    pattern = fr'\blogger\.{method}\b'
                    match = re.search(pattern, line)
                    if match:
                        break
                
                if match:
                    start_line_idx = i
                    start_col_idx = match.start()
                    
                    # 找到表达式的结束位置
                    end_line_idx, end_col_idx = find_expression_end(lines, start_line_idx, start_col_idx)
                    
                    # 检查表达式是否跨越多行
                    if start_line_idx == end_line_idx:
                        # 单行logger调用，替换为{}
                        # 获取缩进
                        indent_match = re.match(r'^(\s*)', lines[start_line_idx])
                        indent = indent_match.group(1) if indent_match else ''
                        
                        # 获取logger调用前的内容
                        before_logger = lines[start_line_idx][:start_col_idx]
                        
                        # 获取logger调用后的内容
                        after_logger = lines[start_line_idx][end_col_idx+1:]
                        
                        # 检查logger调用前是否有语句（如if）
                        before_trimmed = before_logger.rstrip()
                        if before_trimmed and not before_trimmed.endswith(';'):
                            # 有语句在logger调用前，保留它
                            new_line = before_logger + '{}' + after_logger
                        else:
                            # 独立语句，直接替换
                            new_line = before_logger + '{}' + after_logger
                        
                        new_lines.append(new_line)
                        i += 1
                    else:
                        # 多行logger调用，注释掉所有相关行
                        for idx in range(start_line_idx, end_line_idx + 1):
                            comment_line = lines[idx]
                            if not comment_line.strip().startswith('//'):
                                cmt_indent_match = re.match(r'^(\s*)', comment_line)
                                if cmt_indent_match:
                                    cmt_indent = cmt_indent_match.group(1)
                                    cmt_rest = comment_line[len(cmt_indent):].rstrip('\n')
                                    new_lines.append(cmt_indent + '//' + cmt_rest + '\n')
                                else:
                                    new_lines.append('//' + comment_line)
                            else:
                                new_lines.append(comment_line)
                        
                        i = end_line_idx + 1
                    
                    modified = True
                else:
                    # 理论上不会到这里，因为has_logger_call为True
                    new_lines.append(line)
                    i += 1
            else:
                new_lines.append(line)
                i += 1
        
        if modified:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            return True
        
        return False
    
    except Exception as e:
        print(f"处理文件 {filepath} 时出错: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """
    主函数
    """
    if len(sys.argv) != 2:
        print("用法: python comment_logger.py <项目根目录>")
        print("示例: python comment_logger.py /path/to/fantasy-bv-source")
        sys.exit(1)
    
    root_dir = sys.argv[1]
    
    if not os.path.isdir(root_dir):
        print(f"错误: 目录不存在: {root_dir}")
        sys.exit(1)
    
    print(f"开始处理目录: {root_dir}")
    print("搜索并处理日志相关代码...")
    print("- 注释特定导入和声明")
    print("- 将logger方法调用替换为空操作")
    
    # 查找所有.kt文件
    processed_count = 0
    error_count = 0
    
    for root, dirs, files in os.walk(root_dir):
        # 跳过构建目录
        if 'build' in dirs:
            dirs.remove('build')
        
        for file in files:
            if file.endswith('.kt'):
                filepath = os.path.join(root, file)
                try:
                    if process_file(filepath):
                        processed_count += 1
                        print(f"已处理: {filepath}")
                except Exception as e:
                    error_count += 1
                    print(f"处理失败: {filepath} - {e}")
    
    print(f"\n处理完成!")
    print(f"成功处理文件数: {processed_count}")
    print(f"处理失败文件数: {error_count}")

if __name__ == "__main__":
    main()