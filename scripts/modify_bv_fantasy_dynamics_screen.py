import os
import sys

def modify_libs_versions_toml(file_path):
    """修改gradle/libs.versions.toml文件：使用稳定依赖版本 + BOM统一管理"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # 步骤1：在[libraries]前添加4行版本定义（核心修改：降低tv版本为稳定版0.6.0）
        insert_lines_version = [
            'androidx-compose = "1.6.0"  # Compose 核心版本\n',
            'androidx-compose-bom = "2024.02.02"  # Compose BOM 版本\n',
            'androidx-tv = "0.6.0"  # TV Compose 稳定版本（1.0.0暂未发布）\n',
            'androidx-lifecycle = "2.7.0"  # Lifecycle 版本\n'
        ]
        libraries_index = None
        for idx, line in enumerate(lines):
            if line.strip() == '[libraries]':
                libraries_index = idx
                break
        if libraries_index is not None:
            for line in reversed(insert_lines_version):
                lines.insert(libraries_index, line)
        
        # 步骤2：在文件末尾追加依赖（核心修改：移除material3手动版本，由BOM管理）
        append_lines = [
            '# 添加的 Compose 相关依赖\n',
            '# Compose BOM（统一管理所有Compose版本）\n',
            'androidx-compose-bom = { module = "androidx.compose:compose-bom", version.ref = "androidx-compose-bom" }\n',
            '# Compose 基础依赖\n',
            'androidx-compose-ui = { module = "androidx.compose.ui:ui", version.ref = "androidx-compose" }\n',
            'androidx-compose-ui-graphics = { module = "androidx.compose.ui:ui-graphics", version.ref = "androidx-compose" }\n',
            'androidx-compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview", version.ref = "androidx-compose" }\n',
            'androidx-compose-foundation = { module = "androidx.compose.foundation:foundation", version.ref = "androidx-compose" }\n',
            'androidx-compose-material3 = { module = "androidx.compose.material3:material3" }\n',  # 移除version.ref，由BOM管理
            'androidx-compose-runtime = { module = "androidx.compose.runtime:runtime", version.ref = "androidx-compose" }\n',
            'androidx-compose-runtime-livedata = { module = "androidx.compose.runtime:runtime-livedata", version.ref = "androidx-compose" }\n',
            '# Compose Navigation\n',
            'androidx-navigation-compose = { module = "androidx.navigation:navigation-compose", version = "2.7.7" }\n',
            '# Compose Activity\n',
            'androidx-activity-compose = { module = "androidx.activity:activity-compose", version = "1.8.2" }\n',
            '# TV Compose 依赖（使用稳定版0.6.0）\n',
            'androidx-tv-foundation = { module = "androidx.tv:tv-foundation", version.ref = "androidx-tv" }\n',
            'androidx-tv-material = { module = "androidx.tv:tv-material", version.ref = "androidx-tv" }\n',
            '# Lifecycle 依赖\n',
            'androidx-lifecycle-runtime-compose = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "androidx-lifecycle" }\n',
            'androidx-lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "androidx-lifecycle" }\n',
            '# Compose 工具依赖\n',
            'androidx-compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling", version.ref = "androidx-compose" }\n',
            'androidx-compose-ui-test-manifest = { module = "androidx.compose.ui:ui-test-manifest", version.ref = "androidx-compose" }\n',
            'androidx-compose-ui-test-junit4 = { module = "androidx.compose.ui:ui-test-junit4", version.ref = "androidx-compose" }\n',
            '[plugins]\n',
            '# 添加 Compose 插件\n',
            'androidx-compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version = "2.0.21" }\n'
        ]
        lines.extend(append_lines)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"✅ 成功修改: {file_path}")
    except Exception as e:
        print(f"❌ 修改 {file_path} 失败: {str(e)}")
        raise

def modify_app_build_gradle_kts(file_path):
    """修改app/build.gradle.kts：替换dependencies块"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_block = """dependencies {
    implementation(project(":app:mobile"))
    implementation(project(":app:tv"))
    implementation(project(":app:shared"))
}"""
        
        new_block = """dependencies {
    implementation(project(":app:mobile"))
    implementation(project(":app:tv"))
    implementation(project(":app:shared"))
    // Compose BOM（统一管理所有Compose版本，避免冲突）
    val composeBom = platform(libs.androidx.compose.bom)
    implementation(composeBom)
    // TV Compose 依赖（使用稳定版0.6.0）
    implementation(libs.androidx.tv.foundation)
    implementation(libs.androidx.tv.material)
    // Compose 基础依赖
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.foundation)
    implementation(libs.androidx.compose.runtime)
    implementation(libs.androidx.compose.runtime.livedata)
    // 其他必要的 Compose 依赖
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.navigation.compose)
    // 调试工具
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
    // 测试依赖
    androidTestImplementation(composeBom)
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
}"""
        
        if original_block in content:
            content = content.replace(original_block, new_block)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ 成功修改: {file_path}")
        else:
            print(f"⚠️ 未找到目标依赖块: {file_path}")
    except Exception as e:
        print(f"❌ 修改 {file_path} 失败: {str(e)}")
        raise

def modify_tv_build_gradle_kts(file_path):
    """修改app/tv/build.gradle.kts：替换dependencies块"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_block = """dependencies {
    implementation(project(":app:shared"))
}"""
        
        new_block = """dependencies {
    implementation(project(":app:shared"))
    // Compose BOM（统一管理所有Compose版本，避免冲突）
    val composeBom = platform(libs.androidx.compose.bom)
    implementation(composeBom)
    // TV Compose 依赖（使用稳定版0.6.0）
    implementation(libs.androidx.tv.foundation)
    implementation(libs.androidx.tv.material)
    // Compose 基础依赖
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.foundation)
    implementation(libs.androidx.compose.runtime)
    // 其他必要的 Compose 依赖
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    // 如果您的 TV 模块需要导航
    implementation(libs.androidx.navigation.compose)
    // 调试工具
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
    // 测试依赖
    androidTestImplementation(composeBom)
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
}"""
        
        if original_block in content:
            content = content.replace(original_block, new_block)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ 成功修改: {file_path}")
        else:
            print(f"⚠️ 未找到目标依赖块: {file_path}")
    except Exception as e:
        print(f"❌ 修改 {file_path} 失败: {str(e)}")
        raise

def modify_dynamics_screen_kt(file_path):
    """修改DynamicsScreen.kt：修复类型不匹配 + 补充Key导入"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # 1. import android.content.Intent 后插入
        target1 = 'import android.content.Intent\n'
        insert1 = 'import androidx.compose.foundation.focusable\n'
        for idx, line in enumerate(lines):
            if line == target1:
                lines.insert(idx+1, insert1)
                break
        
        # 2. import androidx.compose.ui.Modifier 后插入5行（新增 Key 导入）
        target2 = 'import androidx.compose.ui.Modifier\n'
        insert2 = [
            'import androidx.compose.ui.focus.FocusDirection\n',
            'import androidx.compose.ui.focus.FocusRequester\n',
            'import androidx.compose.ui.focus.focusProperties\n',
            'import androidx.compose.ui.focus.focusRequester\n',
            'import androidx.compose.ui.input.key.Key\n'  # 新增：解决 Key.Left/Key.Down 未解析
        ]
        for idx, line in enumerate(lines):
            if line == target2:
                for l in reversed(insert2):
                    lines.insert(idx+1, l)
                break
        
        # 3. val scope = rememberCoroutineScope() 后插入3行
        target3 = '    val scope = rememberCoroutineScope()\n'
        insert3 = [
            '    val gridFocusRequester = remember { FocusRequester() }\n',
            '    val gridColumns = 4 // Grid固定列数\n',
            '    val isGridLoadingOrEmpty by remember { derivedStateOf { dynamicViewModel.loadingVideo || dynamicViewModel.dynamicVideoList.isEmpty() } }\n'
        ]
        for idx, line in enumerate(lines):
            if line == target3:
                for l in reversed(insert3):
                    lines.insert(idx+1, l)
                break
        
        # 4. .fillMaxSize() 后插入6行（修复 focusProperties 类型不匹配）
        target4 = '                    .fillMaxSize()\n'
        # 核心修复：enter/exit 返回 gridFocusRequester，匹配 API 要求的 FocusRequester? 类型
        insert4 = [
            '                    .focusProperties {\n',
            '                        canFocus = true\n',
            '                        enter = { gridFocusRequester }\n',  # 替换原 FocusDirection.Next
            '                        exit = { gridFocusRequester }\n',  # 替换原 FocusDirection.Previous
            '                    }\n',
            '                    .focusRequester(gridFocusRequester)\n'
        ]
        for idx, line in enumerate(lines):
            if line == target4:
                for l in reversed(insert4):
                    lines.insert(idx+1, l)
                break
        
        # 5. .onPreviewKeyEvent { 后插入22行
        target5 = '                    .onPreviewKeyEvent {\n'
        insert5 = [
            '                        // 第一层防护：加载/空列表拦截所有方向键\n',
            '                        if (isGridLoadingOrEmpty && it.type == KeyEventType.KeyDown) {\n',
            '                            gridFocusRequester.requestFocus()\n',
            '                            return@onPreviewKeyEvent true\n',
            '                        }\n',
            '                        // 第二层防护：第一列拦截左方向键\n',
            '                        if (it.type == KeyEventType.KeyDown && it.key == Key.Left) {\n',
            '                            val isFirstColumn = currentFocusedIndex >= 0 && (currentFocusedIndex % gridColumns == 0)\n',
            '                            if (isFirstColumn) {\n',
            '                                gridFocusRequester.requestFocus()\n',
            '                                return@onPreviewKeyEvent true\n',
            '                            }\n',
            '                        }\n',
            '                        // 第三层防护：到底部拦截下方向键\n',
            '                        if (it.type == KeyEventType.KeyDown && it.key == Key.Down) {\n',
            '                            val isLastItem = currentFocusedIndex >= dynamicViewModel.dynamicVideoList.size - 1\n',
            '                            if (isLastItem && !dynamicViewModel.videoHasMore) {\n',
            '                                gridFocusRequester.requestFocus()\n',
            '                                return@onPreviewKeyEvent true\n',
            '                            }\n',
            '                        }\n',
            '                        // 保留原有Menu键逻辑\n'
        ]
        for idx, line in enumerate(lines):
            if line == target5:
                for l in reversed(insert5):
                    lines.insert(idx+1, l)
                break
        
        # 6. 匹配Box中的 modifier = Modifier.fillMaxSize() 行（兼容有无逗号）
        target6_idx = -1
        for idx, line in enumerate(lines):
            stripped_line = line.strip()
            if stripped_line == 'modifier = Modifier.fillMaxSize()' or stripped_line == 'modifier = Modifier.fillMaxSize(),':
                target6_idx = idx
                break
        
        if target6_idx != -1:
            original_line = lines[target6_idx]
            if original_line.strip().endswith(','):
                lines[target6_idx] = original_line.replace(',\n', '\n').rstrip(',') + '\n'
            
            insert6 = [
                '                                .focusRequester(gridFocusRequester)\n',
                '                                .focusable(),\n'
            ]
            for l in reversed(insert6):
                lines.insert(target6_idx + 1, l)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"✅ 成功修改: {file_path}")
    except Exception as e:
        print(f"❌ 修改 {file_path} 失败: {str(e)}")
        raise

def main():
    if len(sys.argv) != 2:
        print("🚫 用法错误！正确用法：")
        print("python modify_files.py <顶级目录>")
        print("示例：python modify_files.py /xxx")
        sys.exit(1)
    
    root_dir = sys.argv[1]
    files = [
        (os.path.join(root_dir, "gradle", "libs.versions.toml"), modify_libs_versions_toml),
        (os.path.join(root_dir, "app", "build.gradle.kts"), modify_app_build_gradle_kts),
        (os.path.join(root_dir, "app", "tv", "build.gradle.kts"), modify_tv_build_gradle_kts),
        (os.path.join(root_dir, "app", "tv", "src", "main", "kotlin", "dev", "aaa1115910", "bv", "tv", "screens", "main", "home", "DynamicsScreen.kt"), modify_dynamics_screen_kt)
    ]
    
    for file_path, _ in files:
        if not os.path.exists(file_path):
            print(f"🚫 文件不存在：{file_path}")
            sys.exit(1)
    
    for file_path, modify_func in files:
        modify_func(file_path)
    
    print("\n🎉 所有文件修改完成！")

if __name__ == "__main__":
    main()