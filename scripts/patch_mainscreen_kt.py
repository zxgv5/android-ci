import re
import sys
import os

def remove_lines_with_keywords(file_path):
    """
    删除Kotlin文件中包含特定关键词且未被注释的代码行
    
    参数:
        file_path: Kotlin源文件路径
    """
    # 修正：移除单词边界，使用更灵活的匹配模式
    # 匹配包含ugc、pgc、live、search（不区分大小写）的行
    keywords_pattern = re.compile(r'ugc|pgc|live|search', re.IGNORECASE)
    
    # 检查文件是否存在
    if not os.path.exists(file_path):
        print(f"错误：文件 '{file_path}' 不存在")
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        new_lines = []
        in_block_comment = False  # 是否在多行注释中
        in_string = False  # 是否在字符串字面量中
        string_char = None  # 字符串分隔符类型: ' 或 "
        
        for line_num, line in enumerate(lines, 1):
            original_line = line
            line = line.rstrip('\n')  # 移除换行符以便处理
            line_len = len(line)
            
            # 跳过空行
            if line_len == 0:
                new_lines.append(original_line)
                continue
            
            # 检查整行是否被单行注释
            stripped_line = line.strip()
            if stripped_line.startswith('//'):
                new_lines.append(original_line)
                continue
            
            # 检查是否在多行注释中开始
            if not in_block_comment:
                # 检查是否以多行注释开始
                if stripped_line.startswith('/*'):
                    in_block_comment = True
                    new_lines.append(original_line)
                    # 检查是否在同一行结束
                    if '*/' in line:
                        in_block_comment = False
                    continue
            
            # 如果在多行注释中
            if in_block_comment:
                new_lines.append(original_line)
                # 检查是否结束多行注释
                if '*/' in line:
                    in_block_comment = False
                continue
            
            # 检查关键词（不在注释中）
            if keywords_pattern.search(line):
                # 进一步验证：确保关键词不在字符串中
                in_string_local = False
                string_char_local = None
                escape_next = False
                has_keyword_outside_string = False
                
                i = 0
                while i < line_len:
                    char = line[i]
                    
                    # 处理转义字符
                    if escape_next:
                        escape_next = False
                        i += 1
                        continue
                    
                    # 处理字符串开始/结束
                    if char == '\\':
                        escape_next = True
                        i += 1
                        continue
                    
                    if char in ('"', "'"):
                        if not in_string_local:
                            in_string_local = True
                            string_char_local = char
                            # 检查是否是三重引号（原始字符串）
                            if i + 2 < line_len and line[i:i+3] == char * 3:
                                i += 2  # 跳过额外的两个引号
                        elif string_char_local == char:
                            # 检查是否是三重引号结束
                            if i + 2 < line_len and line[i:i+3] == char * 3:
                                i += 2  # 跳过额外的两个引号
                            in_string_local = False
                            string_char_local = None
                    
                    i += 1
                
                # 重新搜索关键词，但排除在字符串中的情况
                i = 0
                in_string_local = False
                string_char_local = None
                escape_next = False
                
                while i < line_len:
                    # 检查从当前位置开始是否匹配关键词
                    match = keywords_pattern.search(line[i:])
                    if not match:
                        break
                    
                    match_start = match.start() + i
                    match_end = match.end() + i
                    
                    # 检查匹配位置是否在字符串中
                    # 重新扫描到匹配位置，跟踪字符串状态
                    temp_i = 0
                    temp_in_string = False
                    temp_string_char = None
                    temp_escape = False
                    
                    while temp_i <= match_start and temp_i < line_len:
                        char = line[temp_i]
                        
                        if temp_escape:
                            temp_escape = False
                            temp_i += 1
                            continue
                        
                        if char == '\\':
                            temp_escape = True
                            temp_i += 1
                            continue
                        
                        if char in ('"', "'"):
                            if not temp_in_string:
                                temp_in_string = True
                                temp_string_char = char
                                # 检查三重引号
                                if temp_i + 2 < line_len and line[temp_i:temp_i+3] == char * 3:
                                    temp_i += 2
                            elif temp_string_char == char:
                                # 检查三重引号结束
                                if temp_i + 2 < line_len and line[temp_i:temp_i+3] == char * 3:
                                    temp_i += 2
                                temp_in_string = False
                                temp_string_char = None
                        
                        temp_i += 1
                    
                    # 如果关键词不在字符串中，则标记为需要删除
                    if not temp_in_string:
                        has_keyword_outside_string = True
                        break
                    
                    # 跳过当前匹配，继续搜索
                    i = match_end
                
                if has_keyword_outside_string:
                    print(f"第 {line_num} 行已删除: {line[:80]}...")
                    continue
            
            new_lines.append(original_line)
        
        # 将修改后的内容写回文件
        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(new_lines)
        
        print(f"处理完成: {file_path}")
        print(f"原始行数: {len(lines)}, 处理后行数: {len(new_lines)}")
        return True
        
    except Exception as e:
        print(f"处理文件时出错: {e}")
        return False


def main():
    """
    主函数：处理命令行参数
    """
    if len(sys.argv) != 2:
        print("使用方法: python kt_cleaner.py <kotlin文件路径>")
        print("示例: python kt_cleaner.py ./src/main/kotlin/MainActivity.kt")
        return
    
    file_path = sys.argv[1]
    success = remove_lines_with_keywords(file_path)
    
    if success:
        print("操作成功完成！")
    else:
        print("操作失败。")


if __name__ == "__main__":
    main()