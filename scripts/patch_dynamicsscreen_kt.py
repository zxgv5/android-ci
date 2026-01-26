import sys
import re

def process_kt_file(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 第一部分：删除指定的代码块
    lines_to_delete = []
    for i, line in enumerate(lines):
        line_content = line.strip()
        # 1. 删除shouldLoadMore函数
        if "val shouldLoadMore by remember {" in line_content:
            # 找到这个函数的结束位置
            j = i
            brace_count = 0
            in_braces = False
            while j < len(lines):
                if "{" in lines[j]:
                    brace_count += 1
                    in_braces = True
                if "}" in lines[j]:
                    brace_count -= 1
                if in_braces and brace_count == 0:
                    # 删除从i到j的所有行
                    for k in range(i, j + 1):
                        if k not in lines_to_delete:
                            lines_to_delete.append(k)
                    break
                j += 1
        
        # 2. 删除LaunchedEffect函数
        if "LaunchedEffect(shouldLoadMore) {" in line_content:
            j = i
            brace_count = 0
            in_braces = False
            while j < len(lines):
                if "{" in lines[j]:
                    brace_count += 1
                    in_braces = True
                if "}" in lines[j]:
                    brace_count -= 1
                if in_braces and brace_count == 0:
                    for k in range(i, j + 1):
                        if k not in lines_to_delete:
                            lines_to_delete.append(k)
                    break
                j += 1
    # 删除所有标记的行（从后往前删除，避免索引问题）
    lines_to_delete.sort(reverse=True)
    for idx in lines_to_delete:
        if idx < len(lines):
            del lines[idx]
    
    # 第二部分：插入新的代码
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        new_lines.append(line)
        
        # 1. 在import org.koin.androidx.compose.koinViewModel后插入import kotlinx.coroutines.delay
        if "import org.koin.androidx.compose.koinViewModel" in line.strip():
            new_lines.append("import kotlinx.coroutines.delay\n")
        
        i += 1
    
    # 第三部分：在showTip语句后插入LaunchedEffect代码块
    # 重新处理new_lines，因为之前已经在其中插入了import
    temp_lines = []
    i = 0
    while i < len(new_lines):
        line = new_lines[i]
        temp_lines.append(line)
        
        # 查找val showTip by remember语句
        if "val showTip by remember {" in line.strip():
            # 找到这个多行语句的结束位置
            brace_count = 0
            found_start = False
            
            # 首先找到语句的开始大括号
            for char in line:
                if char == '{':
                    brace_count += 1
                    found_start = True
            
            # 继续查找直到所有大括号匹配完成
            j = i
            while j < len(new_lines) and brace_count > 0:
                if j != i:  # 第一行已经处理过了
                    temp_lines.append(new_lines[j])
                    # 统计这一行中的大括号
                    for char in new_lines[j]:
                        if char == '{':
                            brace_count += 1
                        elif char == '}':
                            brace_count -= 1
                j += 1
                
            # 更新i到语句的结束位置
            i = j - 1  # 因为循环末尾会i+=1
            
            # 在showTip语句结束后插入LaunchedEffect代码
            if brace_count == 0:  # 确保括号匹配完成
                launcher_code = """    LaunchedEffect(lazyGridState, dynamicViewModel) {
        while (true) {
            delay(150L)
            val listSize = dynamicViewModel.dynamicVideoList.size
            if (listSize == 0) continue
            val lastVisibleIndex = lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1
            if (lastVisibleIndex >= listSize - 24) {
                scope.launch(Dispatchers.IO) {
                    dynamicViewModel.loadMoreVideo()
                }
            }
        }
    }
"""
                # 检查下一行是否为空行，如果不是则添加空行
                if i + 1 < len(new_lines) and new_lines[i + 1].strip() != "":
                    temp_lines.append("\n")
                temp_lines.append(launcher_code)
        
        i += 1
    
    # 如果temp_lines不为空，使用它作为最终结果
    if temp_lines:
        new_lines = temp_lines
    
    # 写入文件
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <filename>")
        sys.exit(1)
    
    filename = sys.argv[1]
    try:
        process_kt_file(filename)
        print(f"Successfully processed {filename}")
    except Exception as e:
        print(f"Error processing file: {e}")
        sys.exit(1)