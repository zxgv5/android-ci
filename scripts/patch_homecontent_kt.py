import re
import sys
import os

def clean_kotlin_file(file_path):
    """
    清理Kotlin文件中包含特定关键词的行和代码块
    
    参数:
        file_path: Kotlin源文件路径
    """
    keywords = ['followingseason', 'toview']
    
    if not os.path.exists(file_path):
        print(f"错误：文件 '{file_path}' 不存在")
        return False
    
    try:
        # 读取文件
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        print(f"开始处理文件: {file_path}")
        print(f"文件总行数: {len(lines)}")
        
        # 标记需要删除的行
        delete_lines = set()
        
        # 第一遍：查找所有含有关键词的行
        for i, line in enumerate(lines):
            # 检查是否包含关键词（不区分大小写）
            line_lower = line.lower()
            contains_keyword = any(keyword in line_lower for keyword in keywords)
            
            if contains_keyword:
                # 检查是否在字符串字面量中
                if not is_in_string_literal(line):
                    delete_lines.add(i)
                    print(f"标记删除行 {i+1}: {line.strip()[:60]}...")
        
        # 第二遍：处理代码块
        i = 0
        while i < len(lines):
            if i in delete_lines and '{' in lines[i]:
                # 找到匹配的闭合括号
                brace_count = 1
                j = i + 1
                
                while j < len(lines) and brace_count > 0:
                    delete_lines.add(j)
                    brace_count += lines[j].count('{')
                    brace_count -= lines[j].count('}')
                    j += 1
                
                print(f"标记代码块: 行 {i+1} 到 {j}")
                i = j  # 跳过已处理的代码块
            else:
                i += 1
        
        # 构建新的文件内容
        new_lines = []
        for i, line in enumerate(lines):
            if i not in delete_lines:
                new_lines.append(line)
        
        # 写回文件
        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(new_lines)
        
        print(f"\n处理完成!")
        print(f"原始行数: {len(lines)}")
        print(f"处理后行数: {len(new_lines)}")
        print(f"删除行数: {len(delete_lines)}")
        
        # 显示被删除的部分
        if delete_lines:
            print("\n被删除的行:")
            for i in sorted(delete_lines):
                if i < len(lines):
                    print(f"  行 {i+1}: {lines[i].strip()[:80]}")
        
        return True
        
    except Exception as e:
        print(f"处理文件时出错: {e}")
        import traceback
        traceback.print_exc()
        return False


def is_in_string_literal(line):
    """
    检查关键词是否在字符串字面量中（简化版）
    
    注意：这个简化版本可能无法处理所有复杂的字符串情况，
    但对于大多数Kotlin代码是有效的
    """
    in_string = False
    string_char = None
    escape_next = False
    
    for i, char in enumerate(line):
        if escape_next:
            escape_next = False
            continue
        
        if char == '\\':
            escape_next = True
            continue
        
        if char in ('"', "'"):
            if not in_string:
                in_string = True
                string_char = char
                # 检查是否是三重引号
                if i + 2 < len(line) and line[i:i+3] == char * 3:
                    return True  # 假设三重引号中的内容都是字符串
            elif string_char == char:
                in_string = False
                string_char = None
    
    return in_string


def main():
    """
    主函数：处理命令行参数
    """
    if len(sys.argv) != 2:
        print("使用方法: python kt_cleaner_fixed.py <kotlin文件路径>")
        print("示例: python kt_cleaner_fixed.py ./MainActivity.kt")
        print("\n功能说明:")
        print("  1. 删除所有包含 'followingseason' 或 'toview' 的行")
        print("  2. 删除这些行所在的完整代码块")
        print("  3. 包括注释中的关键词也会被删除")
        return
    
    file_path = sys.argv[1]
    
    success = clean_kotlin_file(file_path)
    
    if success:
        print("\n操作成功完成！")
    else:
        print("\n操作失败。")


if __name__ == "__main__":
    main()