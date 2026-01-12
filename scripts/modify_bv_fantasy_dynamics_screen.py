#!/usr/bin/env python3
"""
方案4自定义焦点导航实现脚本
针对 DynamicsScreen.kt 文件，解决焦点异常移出问题
"""

import re
import sys
import os

def apply_custom_focus_navigation(file_path):
    """
    应用方案4自定义焦点导航，解决焦点异常移出问题
    """
    
    if not os.path.exists(file_path):
        print(f"错误: 文件不存在: {file_path}")
        return False
    
    # 读取文件内容
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 创建备份文件
    backup_path = file_path + '.bak'
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"已创建备份文件: {backup_path}")
    
    # 第一步：修改 onPreviewKeyEvent 部分，应用完整的方案4
    # 查找原始的 onPreviewKeyEvent 代码块
    original_key_event_pattern = r'\.onPreviewKeyEvent\s*\{[\s\S]*?false\s*\}'
    
    # 方案4的完整自定义焦点导航代码
    custom_navigation_code = '''.onPreviewKeyEvent { event ->
                        when {
                            event.type == KeyEventType.KeyDown -> {
                                when (event.key) {
                                    Key.DirectionDown -> {
                                        if (dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0) {
                                            val nextIndex = currentFocusedIndex + 4 // 下方向键移动4列（网格宽度）
                                            // 确保目标位置已加载
                                            if (nextIndex < dynamicViewModel.dynamicVideoList.size) {
                                                currentFocusedIndex = nextIndex
                                                scope.launch {
                                                    lazyGridState.scrollToItem(nextIndex)
                                                }
                                                true // 消费事件，阻止默认焦点移动
                                            } else if (nextIndex >= dynamicViewModel.dynamicVideoList.size && dynamicViewModel.videoHasMore && !dynamicViewModel.loadingVideo) {
                                                // 触发加载更多，但不移动焦点
                                                scope.launch(Dispatchers.IO) {
                                                    dynamicViewModel.loadMoreVideo()
                                                }
                                                true // 消费事件，阻止焦点移出
                                            } else {
                                                // 已到底部或正在加载，阻止焦点移出
                                                true
                                            }
                                        } else {
                                            // 列表为空或没有焦点，阻止默认导航
                                            true
                                        }
                                    }
                                    Key.DirectionUp -> {
                                        if (dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0) {
                                            val nextIndex = currentFocusedIndex - 4 // 上方向键移动4列
                                            if (nextIndex >= 0) {
                                                currentFocusedIndex = nextIndex
                                                scope.launch {
                                                    lazyGridState.scrollToItem(nextIndex)
                                                }
                                                true
                                            } else {
                                                // 已到顶部，阻止焦点移出网格
                                                true
                                            }
                                        } else {
                                            true
                                        }
                                    }
                                    Key.DirectionRight -> {
                                        if (dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0) {
                                            val nextIndex = currentFocusedIndex + 1
                                            // 检查是否在同一行（防止跨行移动）
                                            val currentRow = currentFocusedIndex / 4
                                            val nextRow = nextIndex / 4
                                            if (nextIndex < dynamicViewModel.dynamicVideoList.size && currentRow == nextRow) {
                                                currentFocusedIndex = nextIndex
                                                scope.launch {
                                                    lazyGridState.scrollToItem(nextIndex)
                                                }
                                                true
                                            } else {
                                                // 阻止移动到下一行或未加载项
                                                true
                                            }
                                        } else {
                                            true
                                        }
                                    }
                                    Key.DirectionLeft -> {
                                        if (dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0) {
                                            val nextIndex = currentFocusedIndex - 1
                                            // 检查是否在同一行
                                            val currentRow = currentFocusedIndex / 4
                                            val nextRow = nextIndex / 4
                                            if (nextIndex >= 0 && currentRow == nextRow) {
                                                currentFocusedIndex = nextIndex
                                                scope.launch {
                                                    lazyGridState.scrollToItem(nextIndex)
                                                }
                                                true
                                            } else {
                                                // 阻止移动到上一行或无效位置
                                                true
                                            }
                                        } else {
                                            true
                                        }
                                    }
                                    Key.Menu -> {
                                        // 不处理KeyDown，等待KeyUp
                                        false
                                    }
                                    else -> false
                                }
                            }
                            event.type == KeyEventType.KeyUp && event.key == Key.Menu -> {
                                context.startActivity(Intent(context, FollowActivity::class.java))
                                true
                            }
                            else -> false
                        }
                    }'''
    
    # 替换 onPreviewKeyEvent 部分
    match = re.search(original_key_event_pattern, content, re.DOTALL)
    if match:
        old_code = match.group(0)
        content = content.replace(old_code, custom_navigation_code)
        print("✓ 已应用方案4自定义焦点导航")
    else:
        print("错误: 未找到 onPreviewKeyEvent 部分")
        return False
    
    # 第二步：改进焦点恢复逻辑
    # 查找原始的 onFocusChanged 代码
    original_focus_changed_code = '''                    .onFocusChanged{
                        if (!it.isFocused) {
                            currentFocusedIndex = -1
                        }
                    }'''
    
    # 改进的 onFocusChanged 代码
    improved_focus_changed_code = '''                    .onFocusChanged{
                        if (it.isFocused) {
                            // 当网格重新获得焦点时，如果之前没有焦点位置且列表不为空，聚焦到第一个项目
                            if (currentFocusedIndex == -1 && dynamicViewModel.dynamicVideoList.isNotEmpty()) {
                                currentFocusedIndex = 0
                            }
                        } else {
                            currentFocusedIndex = -1
                        }
                    }'''
    
    if original_focus_changed_code in content:
        content = content.replace(original_focus_changed_code, improved_focus_changed_code)
        print("✓ 已改进焦点恢复逻辑")
    
    # 第三步：优化 shouldLoadMore 条件
    # 查找原始的 shouldLoadMore 定义
    original_should_load_more = '''    val shouldLoadMore by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex + 12 > dynamicViewModel.dynamicVideoList.size }
    }'''
    
    # 优化后的 shouldLoadMore 定义
    # 从 +12 改为 +8，提前触发加载，为焦点移动预留缓冲
    optimized_should_load_more = '''    val shouldLoadMore by remember {
        derivedStateOf { 
            dynamicViewModel.dynamicVideoList.isNotEmpty() && 
            currentFocusedIndex >= 0 &&
            currentFocusedIndex + 8 > dynamicViewModel.dynamicVideoList.size &&
            dynamicViewModel.videoHasMore &&
            !dynamicViewModel.loadingVideo
        }
    }'''
    
    if original_should_load_more in content:
        content = content.replace(original_should_load_more, optimized_should_load_more)
        print("✓ 已优化 shouldLoadMore 触发条件（从+12改为+8）")
    
    # 第四步：保存修改后的文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("=" * 60)
    print("方案4自定义焦点导航实现完成！")
    print("\n主要修改内容：")
    print("1. 应用了方案4的完整自定义焦点导航逻辑")
    print("2. 改进了焦点恢复逻辑，重新获得焦点时会聚焦到第一个项目")
    print("3. 优化了 shouldLoadMore 触发条件，提前触发数据加载")
    print("\n方案4核心特性：")
    print("• 完全接管方向键导航，阻止系统默认焦点移动")
    print("• 确保焦点只在已加载数据范围内移动")
    print("• 当焦点接近底部时自动触发加载，但焦点保持原位")
    print("• 防止焦点跨行移动和移出网格边界")
    print("• 保持 Menu 键原有功能不变")
    print("\n已创建的备份文件可用于恢复：")
    print(f"  {backup_path}")
    
    return True

def main():
    if len(sys.argv) != 2:
        print("使用方法: python apply_solution4.py <kt_file_path>")
        print("示例: python apply_solution4.py DynamicsScreen.kt")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    if not file_path.endswith('.kt'):
        print("警告: 文件不是 .kt 后缀，可能不是 Kotlin 文件")
        response = input("是否继续? (y/N): ")
        if response.lower() != 'y':
            sys.exit(0)
    
    print(f"正在处理文件: {file_path}")
    print("=" * 60)
    print("应用方案4：自定义焦点导航")
    print("=" * 60)
    
    success = apply_custom_focus_navigation(file_path)
    
    if success:
        print("\n✓ 方案4实现成功！")
        print("\n问题分析回顾：")
        print("原问题：长按下方向键快速浏览时，焦点会异常移出页面")
        print("原因：异步数据加载速度跟不上焦点移动速度，导致焦点移动到未加载区域")
        print("方案4解决方案：")
        print("  1. 完全自定义焦点导航逻辑，阻止系统默认行为")
        print("  2. 焦点只允许在已加载数据范围内移动")
        print("  3. 提前触发数据加载，为焦点移动预留缓冲")
        print("  4. 添加边界检查，防止焦点移出网格")
        print("\n测试建议：")
        print("1. 编译并运行应用")
        print("2. 长按下方向键测试快速滚动")
        print("3. 观察焦点是否会停留在网格内")
        print("4. 测试数据加载期间的焦点行为")
        print("5. 测试各个方向键在边界情况下的行为")
    else:
        print("\n✗ 实现失败")
        sys.exit(1)

if __name__ == "__main__":
    main()