#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
注释日志工具
用于注释掉Kotlin项目中特定的日志相关代码，并将logger方法调用替换为空操作
对于函数的处理，可以正确识别函数整体，处理多行情况
主要注释以下内容：
# import io.github.oshai.kotlinlogging.KotlinLogging
# import dev.aaa1115910.bv.util.fInfo
# KotlinLogging.logger
# logger("BvVideoPlayer")
# logger("BvPlayer")
# androidLogger
# logger.info { xxx }   -> 替换为 {}
# logger.fInfo { xxx }  -> 替换为 {}
# logger.warn { xxx }   -> 替换为 {}
# logger.fWarn { xxx }  -> 替换为 {}
# logger.error { xxx }  -> 替换为 {}
# logger.fError { xxx } -> 替换为 {}
# logger.exception { xxx } -> 替换为 {}
# logger.fException { xxx } -> 替换为 {}
# logger.debug { xxx }  -> 替换为 {}
# logger.fDebug { xxx } -> 替换为 {}
# addLogs(...)          -> 整行注释（多行时逐行注释）
"""
import os
import re
import sys

LOGGER_METHODS = ['info', 'fInfo', 'warn', 'fWarn', 'error',
                  'fError', 'exception', 'fException', 'debug', 'fDebug']

FUNCTION_CALLS_TO_REPLACE = ['addLogs']

def is_function_declaration(lines, line_idx, col_idx, func_name):
    line = lines[line_idx]
    before = line[:col_idx]
    if re.search(r'\bfun\s+\w*\s*$', before):
        return True
    return False

def find_expression_end(lines, start_line_idx, start_col_idx):
    """
    找到从 logger.method 之后开始的表达式结束位置（适用于各种形式）
    返回 (line_idx, col_idx) 指向结束括号/花括号
    """
    line_idx = start_line_idx
    col_idx = start_col_idx

    paren_count = 0
    brace_count = 0
    in_string = False
    string_char = None
    escape = False

    # 定位到 logger.method 之后（即第一个非标识符字符处）
    for method in LOGGER_METHODS:
        pattern = fr'logger\.{method}\b'
        match = re.search(pattern, lines[line_idx][col_idx:])
        if match:
            col_idx = col_idx + match.start()
            break

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
                    if paren_count == 0 and brace_count == 0:
                        return i, j
                elif char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0 and paren_count == 0:
                        return i, j
                elif char in ('"', "'"):
                    in_string = True
                    string_char = char
            else:
                if char == string_char:
                    in_string = False
                    string_char = None
        col_idx = 0

    return len(lines) - 1, len(lines[-1]) - 1

def comment_out_lines(new_lines, lines, start_idx, end_idx):
    """将指定范围的行注释掉，保留缩进"""
    for idx in range(start_idx, end_idx + 1):
        comment_line = lines[idx]
        if not comment_line.strip().startswith('//'):
            indent_match = re.match(r'^(\s*)', comment_line)
            if indent_match:
                indent = indent_match.group(1)
                rest = comment_line[len(indent):].rstrip('\n')
                new_lines.append(indent + '//' + rest + '\n')
            else:
                new_lines.append('//' + comment_line)
        else:
            new_lines.append(comment_line)

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        modified = False
        new_lines = []
        i = 0

        while i < len(lines):
            line = lines[i]
            should_comment = False

            # 检查需要整行注释的导入和声明
            if re.search(r'^\s*import\s+io\.github\.oshai\.kotlinlogging\.KotlinLogging', line):
                should_comment = True
            elif re.search(r'^\s*import\s+dev\.aaa1115910\.bv\.util\.fInfo', line):
                should_comment = True
            elif re.search(r'\bKotlinLogging\.logger\s*\{', line):
                should_comment = True
            elif re.search(r'\bKotlinLogging\.logger\s*\(', line):
                should_comment = True
            elif re.search(r'\blogger\s*\(\s*["\']BvVideoPlayer["\']\s*\)', line):
                should_comment = True
            elif re.search(r'\bandroidLogger\b', line):
                should_comment = True

            # 检查 logger 方法调用
            has_logger_call = False
            for method in LOGGER_METHODS:
                if re.search(fr'\blogger\.{method}\b', line):
                    has_logger_call = True
                    break

            # 检查 addLogs 调用（排除函数声明）
            has_function_call = False
            match_pos = -1
            for func in FUNCTION_CALLS_TO_REPLACE:
                pattern = fr'\b{func}\s*\('
                match = re.search(pattern, line)
                if match:
                    if not is_function_declaration(lines, i, match.start(), func):
                        has_function_call = True
                        match_pos = match.start()
                        break

            if should_comment and not line.strip().startswith('//'):
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
                # 找到具体匹配的 logger 方法
                match = None
                for method in LOGGER_METHODS:
                    pattern = fr'\blogger\.{method}\b'
                    match = re.search(pattern, line)
                    if match:
                        break

                if match:
                    start_line_idx = i
                    start_col_idx = match.start()

                    # 统一查找表达式结束位置
                    end_line_idx, end_col_idx = find_expression_end(
                        lines, start_line_idx, start_col_idx
                    )

                    # 构造替换行：将整个 logger.method(...) 或 logger.method {...} 替换为 {}
                    before = lines[start_line_idx][:start_col_idx]
                    after = lines[end_line_idx][end_col_idx + 1:] if end_col_idx + 1 < len(lines[end_line_idx]) else ''
                    # 去掉 after 末尾可能原有的换行符，后续统一加回
                    if after.endswith('\n'):
                        after = after[:-1]
                    replacement = before + '{}' + after
                    new_lines.append(replacement + '\n')
                    modified = True
                    i = end_line_idx + 1   # 跳过表达式占用的剩余行
                else:
                    new_lines.append(line)
                    i += 1

            elif has_function_call:
                start_line_idx = i
                start_col_idx = match_pos
                # 对于 addLogs 直接注释
                end_line_idx, end_col_idx = find_expression_end(
                    lines, start_line_idx, start_col_idx
                )
                comment_out_lines(new_lines, lines, start_line_idx, end_line_idx)
                modified = True
                i = end_line_idx + 1

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
    if len(sys.argv) != 2:
        print("用法: python comment_logger.py <项目根目录>")
        sys.exit(1)

    root_dir = sys.argv[1]
    if not os.path.isdir(root_dir):
        print(f"错误: 目录不存在: {root_dir}")
        sys.exit(1)

    print(f"开始处理目录: {root_dir}")
    processed_count = 0
    error_count = 0

    for root, dirs, files in os.walk(root_dir):
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

    print(f"\n处理完成! 成功: {processed_count}, 失败: {error_count}")

if __name__ == "__main__":
    main()