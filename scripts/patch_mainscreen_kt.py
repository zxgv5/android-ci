import re
import sys
import os

def remove_navigation_items(file_path):
    """
    专门删除Kotlin文件中导航按钮相关的代码，而不是删除所有包含关键词的行
    只删除特定的导航菜单项，保留页面实现代码
    """
    # 检查文件是否存在
    if not os.path.exists(file_path):
        print(f"错误：文件 '{file_path}' 不存在")
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        new_lines = []
        
        # 标记是否在导航相关的代码块中
        in_nav_block = False
        nav_block_indent = 0
        
        for line_num, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # 1. 处理 DrawerContent.kt 中的导航项
            if "DrawerContent.kt" in file_path:
                # 删除特定的导航菜单项
                if any(pattern in stripped for pattern in [
                    'NavigationMenuItem.Live', 
                    'NavigationMenuItem.PGC',
                    'NavigationMenuItem.UGC',
                    'NavigationMenuItem.Search',
                    'LiveNavigationMenuItem', 
                    'PGCNavigationMenuItem',
                    'UGCNavigationMenuItem',
                    'SearchNavigationMenuItem'
                ]):
                    print(f"删除导航菜单项 (DrawerContent): 行 {line_num}: {stripped[:60]}...")
                    continue
            
            # 2. 处理 MainScreen.kt 中的导航
            elif "MainScreen.kt" in file_path:
                # 删除特定的导航相关代码
                if any(pattern in stripped for pattern in [
                    'HomeTopNavItem.Live',
                    'HomeTopNavItem.PGC',
                    'HomeTopNavItem.UGC',
                    'HomeTopNavItem.Search'
                ]):
                    print(f"删除导航项 (MainScreen): 行 {line_num}: {stripped[:60]}...")
                    continue
                
                # 检查是否在 when 表达式中的导航块
                if 'when (currentTab)' in stripped or 'when (selectedItem)' in stripped:
                    in_nav_block = True
                    nav_block_indent = len(line) - len(line.lstrip())
                
                if in_nav_block:
                    # 计算当前行的缩进
                    current_indent = len(line) - len(line.lstrip())
                    
                    # 如果缩进小于导航块缩进，说明导航块结束
                    if current_indent <= nav_block_indent and stripped and not stripped.startswith(('}', ')')):
                        in_nav_block = False
                    
                    # 在导航块中，删除包含特定关键词的case
                    if in_nav_block and any(keyword in stripped.lower() for keyword in ['live', 'pgc', 'ugc', 'search']):
                        print(f"删除导航case (MainScreen): 行 {line_num}: {stripped[:60]}...")
                        continue
            
            # 3. 对于其他文件，只删除非常明确的导航按钮代码，不删除类型引用
            else:
                # 只删除包含特定导航按钮文本的行
                if any(pattern in stripped for pattern in [
                    'text = "直播"',
                    'text = "PGC"',
                    'text = "UGC"',
                    'text = "搜索"',
                    'icon = Icons.Default.LiveTv',
                    'icon = Icons.Default.Pgc',
                    'icon = Icons.Default.Ugc',
                    'icon = Icons.Default.Search',
                    '.Live ->',
                    '.PGC ->',
                    '.UGC ->',
                    '.Search ->'
                ]):
                    print(f"删除导航按钮: 行 {line_num}: {stripped[:60]}...")
                    continue
            
            # 保留这一行
            new_lines.append(line)
        
        # 将修改后的内容写回文件
        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(new_lines)
        
        print(f"处理完成: {file_path}")
        print(f"原始行数: {len(lines)}, 处理后行数: {len(new_lines)}")
        return True
        
    except Exception as e:
        print(f"处理文件时出错: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """
    主函数：处理命令行参数
    """
    if len(sys.argv) != 2:
        print("使用方法: python patch_mainscreen_kt.py <kotlin文件路径>")
        print("示例: python patch_mainscreen_kt.py ./MainScreen.kt")
        print("\n功能：删除特定导航按钮，但保留页面实现代码")
        return
    
    file_path = sys.argv[1]
    success = remove_navigation_items(file_path)
    
    if success:
        print("操作成功完成！")
    else:
        print("操作失败。")

if __name__ == "__main__":
    main()