#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修改DynamicsScreen.kt，实现焦点锁定功能
使用方式：python3 modify_bv_fantasy_dynamics_screen.py /path/to/DynamicsScreen.kt
"""
import sys
import os
import re

def validate_file(file_path):
    if not os.path.exists(file_path):
        print(f"[ERROR] 文件不存在：{file_path}", file=sys.stderr)
        sys.exit(1)
    if not os.access(file_path, os.R_OK):
        print(f"[ERROR] 文件无读取权限：{file_path}", file=sys.stderr)
        sys.exit(1)

def read_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(file_path, content):
    temp_file = f"{file_path}.tmp"
    try:
        with open(temp_file, 'w', encoding='utf-8') as f:
            f.write(content)
        os.replace(temp_file, file_path)
        print(f"[SUCCESS] 文件已写入：{file_path}")
    except Exception as e:
        print(f"[ERROR] 写入文件失败：{e}", file=sys.stderr)
        if os.path.exists(temp_file):
            os.remove(temp_file)
        sys.exit(1)

def add_focus_imports(content):
    """添加焦点相关导入（补充所有缺失API，缩进无关）"""
    pattern = re.compile(r'(import androidx\.compose\.ui\.focus\.onFocusChanged\n)')
    # 核心修改：补充 focus/focusable/focusRestrict/KeyDirectionDown 导入
    new_imports = """import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.foundation.focus.focus
import androidx.compose.foundation.focus.focusable
import androidx.compose.foundation.focus.focusRestrict
import androidx.tv.foundation.focus.FocusRestriction
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.KeyDirectionLeft
import androidx.compose.ui.focus.KeyDirectionDown
"""
    if pattern.search(content):
        content = pattern.sub(new_imports, content)
        print("[SUCCESS] 已添加焦点相关导入（含缺失API）")
    else:
        print("[ERROR] 未找到onFocusChanged导入行", file=sys.stderr)
        sys.exit(1)
    return content

def add_focus_variables(content):
    """添加焦点控制变量（严格4空格缩进）"""
    pattern = re.compile(r'(val scope = rememberCoroutineScope\(\)\n)')
    # 严格4空格缩进，匹配原文件层级
    new_vars = """val scope = rememberCoroutineScope()
    val gridFocusRequester = remember { FocusRequester() }
    val gridColumns = 4 // Grid固定列数
    val isGridLoadingOrEmpty by remember { derivedStateOf { dynamicViewModel.loadingVideo || dynamicViewModel.dynamicVideoList.isEmpty() } }
"""
    if pattern.search(content):
        content = pattern.sub(new_vars, content)
        print("[SUCCESS] 已添加焦点控制变量")
    else:
        print("[ERROR] 未找到scope变量行", file=sys.stderr)
        sys.exit(1)
    return content

def add_grid_focus_modifiers(content):
    """添加Grid焦点修饰符（严格对齐缩进）"""
    pattern = re.compile(r'(                    \.fillMaxSize\(\)\n)')
    # LazyVerticalGrid内的modifier链式调用，缩进16空格（4*4）
    new_modifiers = """                    .fillMaxSize()
                    .focusRestrict(FocusRestriction.Scrollable)
                    .focusRequester(gridFocusRequester)
"""
    if pattern.search(content):
        content = pattern.sub(new_modifiers, content)
        print("[SUCCESS] 已添加Grid焦点锁定修饰符")
    else:
        print("[ERROR] 未找到LazyVerticalGrid的fillMaxSize行", file=sys.stderr)
        sys.exit(1)
    return content

def replace_preview_key_event(content):
    """替换onPreviewKeyEvent逻辑（严格4空格缩进）"""
    old_key_event = r"""                    .onPreviewKeyEvent {
                        if\(it\.type == KeyEventType\.KeyUp && it\.key == Key\.Menu\) {
                            context\.startActivity\(Intent\(context, FollowActivity::class\.java\)\)
                            return@onPreviewKeyEvent true
                        }
                        false
                    },"""
    # 严格遵循4空格缩进层级：
    # .onPreviewKeyEvent { → 16空格
    # 内部逻辑 → 20空格（16+4）
    new_key_event = """                    .onPreviewKeyEvent {
                        // 第一层防护：加载/空列表拦截所有方向键
                        if (isGridLoadingOrEmpty && it.type == KeyEventType.KeyDown) {
                            gridFocusRequester.requestFocus()
                            return@onPreviewKeyEvent true
                        }
                        // 第二层防护：第一列拦截左方向键
                        if (it.type == KeyEventType.KeyDown && it.key == KeyDirectionLeft) {
                            val isFirstColumn = currentFocusedIndex >= 0 && (currentFocusedIndex % gridColumns == 0)
                            if (isFirstColumn) {
                                gridFocusRequester.requestFocus()
                                return@onPreviewKeyEvent true
                            }
                        }
                        // 第三层防护：到底部拦截下方向键
                        if (it.type == KeyEventType.KeyDown && it.key == KeyDirectionDown) {
                            val isLastItem = currentFocusedIndex >= dynamicViewModel.dynamicVideoList.size - 1
                            if (isLastItem && !dynamicViewModel.videoHasMore) {
                                gridFocusRequester.requestFocus()
                                return@onPreviewKeyEvent true
                            }
                        }
                        // 保留原有Menu键逻辑
                        if (it.type == KeyEventType.KeyUp && it.key == Key.Menu) {
                            context.startActivity(Intent(context, FollowActivity::class.java))
                            return@onPreviewKeyEvent true
                        }
                        false
                    },"""
    pattern = re.compile(old_key_event, re.DOTALL)
    if pattern.search(content):
        content = pattern.sub(new_key_event, content)
        print("[SUCCESS] 已替换onPreviewKeyEvent逻辑")
    else:
        print("[ERROR] 未找到原有onPreviewKeyEvent块", file=sys.stderr)
        sys.exit(1)
    return content

def add_loading_tip_focus(content):
    """核心修复：替换LoadingTip块为缩进完美版本"""
    # 匹配整个loadingVideo块（忽略原有缩进）
    loading_pattern = re.compile(
        r'(if \(dynamicViewModel.loadingVideo\) \{.*?\}\s*\}\s*\})',
        re.DOTALL
    )
    
    # 严格4空格缩进的LoadingTip块（固定格式，100%规范）
    perfect_loading_block = """if (dynamicViewModel.loadingVideo) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Box(
                            modifier = Modifier.fillMaxSize()
                                .focusRequester(gridFocusRequester)
                                .focusable(),
                            contentAlignment = Alignment.Center
                        ) {
                            LoadingTip()
                        }
                    }
                }"""
    
    # 执行替换
    new_content, count = loading_pattern.subn(perfect_loading_block, content)
    if count == 0:
        print("[ERROR] 未找到LoadingTip所在的代码块", file=sys.stderr)
        sys.exit(1)
    
    # 调试输出替换后的块
    print("[DEBUG] 替换后的LoadingTip块（缩进完美）：")
    print(perfect_loading_block)
    print("[SUCCESS] 已给LoadingTip添加焦点能力（缩进完美）")
    return new_content

def verify_modifications(file_path):
    """验证修改结果（含缩进检查+新增缺失API验证）"""
    print("\n[INFO] 开始验证修改结果...")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 基础验证项 + 新增缺失API验证项
    checks = [
        ("焦点导入", "import androidx.tv.foundation.focus.FocusRestriction"),
        ("焦点变量", "val gridFocusRequester = remember { FocusRequester() }"),
        ("Grid焦点修饰符", ".focusRestrict(FocusRestriction.Scrollable)"),
        ("KeyEvent逻辑", "isGridLoadingOrEmpty && it.type == KeyEventType.KeyDown"),
        ("LoadingTip焦点-1", ".focusRequester(gridFocusRequester)"),
        ("LoadingTip焦点-2", ".focusable()"),
        # 新增验证项：确保缺失的API导入成功
        ("focus API导入", "import androidx.compose.foundation.focus.focus"),
        ("focusable API导入", "import androidx.compose.foundation.focus.focusable"),
        ("focusRestrict API导入", "import androidx.compose.foundation.focus.focusRestrict"),
        ("KeyDirectionDown导入", "import androidx.compose.ui.focus.KeyDirectionDown")
    ]
    
    all_passed = True
    for check_name, check_str in checks:
        if check_str in content:
            print(f"[SUCCESS] {check_name} 验证通过")
        else:
            print(f"[ERROR] {check_name} 验证失败（未找到：{check_str}）", file=sys.stderr)
            all_passed = False
    
    # 缩进合规性检查（关键）
    loading_block = re.search(r'if \(dynamicViewModel.loadingVideo\) \{.*?\}\s*\}\s*\}', content, re.DOTALL)
    if loading_block:
        block_content = loading_block.group(0)
        # 检查核心缩进点
        if "                    item(span = { GridItemSpan(maxLineSpan) }) {" in block_content and \
           "                        Box(" in block_content and \
           "                            modifier = Modifier.fillMaxSize()" in block_content and \
           "                                .focusRequester(gridFocusRequester)" in block_content and \
           "                            LoadingTip()" in block_content:
            print(f"[SUCCESS] LoadingTip块缩进 验证通过（符合4空格规范）")
        else:
            print(f"[WARNING] LoadingTip块缩进可能不规范，但功能不受影响", file=sys.stderr)
    
    if not all_passed:
        sys.exit(1)
    print("[SUCCESS] 所有修改验证通过！")

def main():
    if len(sys.argv) != 2:
        print(f"使用方式：{sys.argv[0]} <DynamicsScreen.kt绝对路径>", file=sys.stderr)
        sys.exit(1)
    
    file_path = sys.argv[1]
    validate_file(file_path)
    content = read_file(file_path)
    
    # 执行所有修改（缩进严格控制）
    content = add_focus_imports(content)
    content = add_focus_variables(content)
    content = add_grid_focus_modifiers(content)
    content = replace_preview_key_event(content)
    content = add_loading_tip_focus(content)
    
    write_file(file_path, content)
    verify_modifications(file_path)

if __name__ == "__main__":
    main()