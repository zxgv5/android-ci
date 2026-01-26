import sys
import re

def process_kt_file(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 第一部分：删除指定的代码块
    lines_to_delete = []
    for i, line in enumerate(lines):
        line_content = line.strip()
        
        # 1. 删除onFocus代码块
        if "onFocus = {" in line_content:
            # 找到这个代码块的结束位置
            j = i
            brace_count = 0
            in_braces = False
            
            # 统计当前行的大括号
            for char in line_content:
                if char == '{':
                    brace_count += 1
                    in_braces = True
            
            # 继续查找直到所有大括号匹配完成
            while j < len(lines) and brace_count > 0:
                if j != i:  # 第一行已经处理过了
                    # 统计这一行中的大括号
                    for char in lines[j]:
                        if char == '{':
                            brace_count += 1
                        elif char == '}':
                            brace_count -= 1
                
                # 标记要删除的行
                if j not in lines_to_delete:
                    lines_to_delete.append(j)
                
                j += 1
    
    # 删除所有标记的行（从后往前删除，避免索引问题）
    lines_to_delete.sort(reverse=True)
    for idx in lines_to_delete:
        if idx < len(lines):
            del lines[idx]
    
    # 第二部分：插入新的代码
    new_lines = []
    
    # 先处理第一部分插入：import语句
    i = 0
    while i < len(lines):
        line = lines[i]
        new_lines.append(line)
        
        # 在import org.koin.androidx.compose.koinViewModel后插入新的import语句
        if "import org.koin.androidx.compose.koinViewModel" in line.strip():
            # 确保下一行不是空行，如果是空行则不需要额外添加空行
            if i + 1 < len(lines) and lines[i + 1].strip() != "":
                new_lines.append("\n")
            
            # 插入新的import语句
            new_imports = """import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

"""
            new_lines.append(new_imports)
        
        i += 1
    
    # 更新lines为插入import后的新内容
    lines = new_lines
    new_lines = []
    
    # 处理第二部分和第三部分插入
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # 替换padding和spacing的值，这3句替换都是针对leonwu85版本的修改，不对fantasy-bv起作用
        # if "contentPadding = PaddingValues(12.dp)" in line.strip():
        #     line = line.replace("12.dp", "24.dp")
        # elif "verticalArrangement = Arrangement.spacedBy(12.dp)" in line.strip():
        #     line = line.replace("12.dp", "24.dp")
        # elif "horizontalArrangement = Arrangement.spacedBy(12.dp)" in line.strip():
        #     line = line.replace("12.dp", "24.dp")
        
        new_lines.append(line)
        
        # 2. 在Scaffold(的上一行插入代码
        if "Scaffold(" in line.strip():
            # 在当前行的上一行插入
            # 首先回溯到上一行（需要从new_lines中弹出当前行）
            new_lines.pop()  # 移除刚才添加的Scaffold行
            
            # 检查上一行是否为空行，如果不是则添加空行
            if i > 0 and lines[i - 1].strip() == "":
                # 上一行已经是空行，不需要额外添加
                pass
            else:
                new_lines.append("\n")
            
            # 插入新的代码
            scaffold_code = """    val lazyGridState = rememberLazyGridState()
    val scope = rememberCoroutineScope()
    LaunchedEffect(lazyGridState, historyViewModel) {
        while (true) {
            delay(150L)
            val listSize = historyViewModel.histories.size
            if (listSize == 0) continue
            val lastVisibleIndex = lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1
            if (lastVisibleIndex >= listSize - 24 && !historyViewModel.noMore) {
                scope.launch(Dispatchers.IO) {
                    historyViewModel.update()
                }
            }
        }
    }

"""
            new_lines.append(scaffold_code)
            
            # 重新添加Scaffold行
            new_lines.append(line)
        
        # 3. 在modifier = Modifier.padding(innerPadding),的上一行插入state = lazyGridState,
        elif "modifier = Modifier.padding(innerPadding)," in line.strip():
            # 在当前行的上一行插入
            # 首先回溯到上一行（需要从new_lines中弹出当前行）
            new_lines.pop()  # 移除刚才添加的modifier行
            
            # 插入state行
            new_lines.append("                state = lazyGridState,\n")
            
            # 重新添加modifier行
            new_lines.append(line)
        
        # 4. 在onLongClick行的下一行插入onFocus = { currentIndex = index }
        elif "onLongClick = { UpInfoActivity.actionStart( context, mid = history.upId, name = history.upName, face = history.upFace ) }," in line.strip():
            new_lines.append("                            onFocus = { currentIndex = index }\n")
        
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