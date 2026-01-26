import sys
import re

def process_kt_file(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 第一部分：删除指定的代码块
    lines_to_delete = []
    for i, line in enumerate(lines):
        line_content = line.strip()
        # 删除shouldLoadMore函数
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
        # 删除LaunchedEffect函数
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
        
        # 1. 在import org.koin.androidx.compose.koinViewModel后插入import kotlinx.coroutines.delay
        if "import org.koin.androidx.compose.koinViewModel" in line.strip():
            new_lines.append(line)
            new_lines.append("import kotlinx.coroutines.delay\n")
        
        # 2. 在val padding = dimensionResource(R.dimen.grid_padding)前一行插入LaunchedEffect代码块
        elif "val padding = dimensionResource(R.dimen.grid_padding)" in line.strip():
            launcher_code = """    LaunchedEffect(lazyGridState, popularViewModel) {
        while (true) {
            delay(150L)
            val listSize = popularViewModel.popularVideoList.size
            if (listSize == 0) continue
            val lastVisibleIndex = lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1
            if (lastVisibleIndex >= listSize - 24) {
                scope.launch(Dispatchers.IO) {
                    popularViewModel.loadMore()
                }
            }
        }
    }
"""
            # 检查前一行是否为空行，如果不是则添加空行
            if len(new_lines) > 0 and new_lines[-1].strip() != "":
                new_lines.append("\n")
            new_lines.append(launcher_code)
            new_lines.append("\n")  # 在代码块后添加一个空行
            new_lines.append(line)
        
        else:
            new_lines.append(line)
        
        i += 1
    
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