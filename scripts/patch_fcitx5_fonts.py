#!/usr/bin/env python3
"""
fcitx5-android 自定义字体补丁脚本 (最终可用版 v2)

用法:
    python patch_font.py /path/to/fcitx5-android
"""

import re
import sys
from pathlib import Path
from typing import List, Optional, Tuple


class FontPatcher:
    def __init__(self, repo_root: str):
        self.repo_root = Path(repo_root)
        self.font_path = "fonts/JetBrainsMapleMono.ttf"

    def run(self):
        print(f"开始修补仓库: {self.repo_root}")
        self.patch_theme_file()
        self.patch_theme_manager_file()
        self.patch_keyview_file()
        self.patch_candidate_files()
        print("所有修补操作已完成。")

    def read_file(self, relative_path: str) -> Optional[str]:
        full_path = self.repo_root / relative_path
        if not full_path.exists():
            print(f"警告: 文件不存在 {full_path}")
            return None
        with open(full_path, 'r', encoding='utf-8') as f:
            return f.read()

    def write_file(self, relative_path: str, content: str):
        full_path = self.repo_root / relative_path
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"已修改: {relative_path}")

    def ensure_import(self, content: str, import_stmt: str) -> Tuple[str, bool]:
        if import_stmt in content:
            return content, False
        lines = content.split('\n')
        package_idx = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('package '):
                package_idx = i
                break
        if package_idx == -1:
            lines.insert(0, import_stmt)
        else:
            insert_idx = package_idx + 1
            while insert_idx < len(lines) and lines[insert_idx].strip() == '':
                insert_idx += 1
            lines.insert(insert_idx, import_stmt)
        return '\n'.join(lines), True

    def _inject_class_body_properties(
        self,
        lines: List[str],
        class_start_line: int,
        props_to_add: List[str],
    ) -> List[str]:
        """在 data class 的类体开头插入属性定义。"""
        i = class_start_line
        while i < len(lines) and '{' not in lines[i]:
            i += 1
        if i >= len(lines):
            return lines
        open_brace_line = i
        indent = '    '
        insert_idx = open_brace_line + 1
        for prop in reversed(props_to_add):
            lines.insert(insert_idx, indent + prop)
        return lines

    def patch_theme_file(self):
        """修改 Theme.kt，添加字体属性为类内 @Transient 属性（两个包）"""
        theme_path = "app/src/main/java/org/fcitx/fcitx5/android/data/theme/Theme.kt"
        content = self.read_file(theme_path)
        if content is None:
            return

        # 添加必需的 import（不再额外导入 Transient，使用全限定名）
        content, _ = self.ensure_import(content, "import android.graphics.Typeface")

        lines = content.split('\n')

        # 1. sealed class Theme 抽象属性
        for i, line in enumerate(lines):
            if line.strip().startswith('sealed class Theme') and '{' in line:
                if not any('abstract val keyTypeface' in l for l in lines[i:i+10]):
                    indent = '    '
                    insert_lines = [
                        indent + "abstract val keyTypeface: Typeface?",
                        indent + "abstract val candidateTypeface: Typeface?"
                    ]
                    j = i + 1
                    while j < len(lines) and lines[j].strip() in ('', '//'):
                        j += 1
                    for idx, ins in enumerate(insert_lines):
                        lines.insert(j + idx, ins)
                break

        # 2. Custom data class
        custom_start = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('data class Custom('):
                custom_start = i
                break
        if custom_start != -1:
            if not any('keyTypeface' in l for l in lines[custom_start:custom_start+50]):
                props = [
                    "@kotlinx.parcelize.Transient @kotlinx.serialization.Transient override var keyTypeface: Typeface? = null",
                    "@kotlinx.parcelize.Transient @kotlinx.serialization.Transient override var candidateTypeface: Typeface? = null"
                ]
                lines = self._inject_class_body_properties(lines, custom_start, props)

        # 3. Builtin data class
        builtin_start = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('data class Builtin('):
                builtin_start = i
                break
        if builtin_start != -1:
            if not any('keyTypeface' in l for l in lines[builtin_start:builtin_start+50]):
                props = [
                    "@kotlinx.parcelize.Transient @kotlinx.serialization.Transient override var keyTypeface: Typeface? = null",
                    "@kotlinx.parcelize.Transient @kotlinx.serialization.Transient override var candidateTypeface: Typeface? = null"
                ]
                lines = self._inject_class_body_properties(lines, builtin_start, props)

        # 4. Monet data class
        monet_start = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('data class Monet('):
                monet_start = i
                break
        if monet_start != -1:
            if not any('keyTypeface' in l for l in lines[monet_start:monet_start+50]):
                props = [
                    "@kotlinx.parcelize.Transient @kotlinx.serialization.Transient override var keyTypeface: Typeface? = null",
                    "@kotlinx.parcelize.Transient @kotlinx.serialization.Transient override var candidateTypeface: Typeface? = null"
                ]
                lines = self._inject_class_body_properties(lines, monet_start, props)

        self.write_file(theme_path, '\n'.join(lines))

    def patch_theme_manager_file(self):
        """修改 ThemeManager.kt，使用正确的 Kotlin 语法"""
        tm_path = "app/src/main/java/org/fcitx/fcitx5/android/data/theme/ThemeManager.kt"
        content = self.read_file(tm_path)
        if content is None:
            return

        content, _ = self.ensure_import(content, "import android.graphics.Typeface")
        content, _ = self.ensure_import(content, "import org.fcitx.fcitx5.android.utils.appContext")

        # 插入字体加载属性
        if 'customKeyTypeface' not in content:
            pattern = r'(object ThemeManager\s*\{)'
            insert_code = f"""
    private val customKeyTypeface by lazy {{
        try {{
            Typeface.createFromAsset(appContext.assets, "{self.font_path}")
        }} catch (e: Exception) {{
            null
        }}
    }}
    private val customCandidateTypeface by lazy {{ customKeyTypeface }}
"""
            content = re.sub(pattern, r'\1' + insert_code, content, count=1)

        # 修改 BuiltinThemes 列表
        if 'copy().apply' not in content:
            content = re.sub(
                r'(val BuiltinThemes = listOf\()([\s\S]*?)(\))',
                lambda m: m.group(1) + re.sub(
                    r'(ThemePreset\.\w+)',
                    r'\1.copy().apply { keyTypeface = customKeyTypeface; candidateTypeface = customCandidateTypeface }',
                    m.group(2)
                ) + m.group(3),
                content,
                flags=re.DOTALL
            )

        # 修改 monetThemes 初始化
        monet_init = 'private var monetThemes = listOf(ThemeMonet.getLight(), ThemeMonet.getDark())'
        if monet_init in content and 'map { it.copy().apply' not in content:
            replacement = 'private var monetThemes = listOf(ThemeMonet.getLight(), ThemeMonet.getDark()).map {\n        it.copy().apply {\n            keyTypeface = customKeyTypeface\n            candidateTypeface = customCandidateTypeface\n        }\n    }'
            content = content.replace(monet_init, replacement)

        # 修改 onSystemPlatteChange 中的 monetThemes 赋值
        onchange_line = 'monetThemes = listOf(ThemeMonet.getLight(), ThemeMonet.getDark())'
        if onchange_line in content and 'map { it.copy().apply' not in content:
            replacement = '''        monetThemes = listOf(ThemeMonet.getLight(), ThemeMonet.getDark()).map {
            it.copy().apply {
                keyTypeface = customKeyTypeface
                candidateTypeface = customCandidateTypeface
            }
        }'''
            content = re.sub(
                r'\s*monetThemes = listOf\(ThemeMonet\.getLight\(\), ThemeMonet\.getDark\(\)\).*',
                replacement,
                content
            )

        # 修改 getTheme 方法
        get_theme_pattern = r'(fun getTheme\(name: String\)\s*=\s*)([^\n]+)'
        match = re.search(get_theme_pattern, content)
        if match:
            original_expr = match.group(2).strip()
            if '?.copy()?.apply' not in original_expr:
                new_expr = f"{original_expr}?.copy()?.apply {{ keyTypeface = customKeyTypeface; candidateTypeface = customCandidateTypeface }}"
                content = content.replace(match.group(0), match.group(1) + new_expr)

        self.write_file(tm_path, content)

    def patch_keyview_file(self):
        """修改 KeyView.kt"""
        kv_path = "app/src/main/java/org/fcitx/fcitx5/android/input/keyboard/KeyView.kt"
        content = self.read_file(kv_path)
        if content is None:
            return

        if 'theme.keyTypeface' not in content:
            content = re.sub(
                r'setTypeface\(typeface,\s*def\.textStyle\)',
                'setTypeface(theme.keyTypeface ?: typeface, def.textStyle)',
                content
            )
        self.write_file(kv_path, content)

    def patch_candidate_files(self):
        """修改候选框渲染文件"""
        ciu_path = "app/src/main/java/org/fcitx/fcitx5/android/input/candidates/CandidateItemUi.kt"
        content = self.read_file(ciu_path)
        if content:
            if 'theme.candidateTypeface' not in content:
                content = re.sub(
                    r'(setTextColor\(theme\.candidateTextColor\))(\s*\n)',
                    r'\1\2        theme.candidateTypeface?.let { setTypeface(it) }\2',
                    content
                )
                self.write_file(ciu_path, content)

        lciu_path = "app/src/main/java/org/fcitx/fcitx5/android/input/candidates/floating/LabeledCandidateItemUi.kt"
        content = self.read_file(lciu_path)
        if content:
            if 'theme.candidateTypeface' not in content:
                content = re.sub(
                    r'(setupTextView\(this\))(\s*\n)',
                    r'\1\2        theme.candidateTypeface?.let { setTypeface(it) }\2',
                    content
                )
                self.write_file(lciu_path, content)


def main():
    if len(sys.argv) != 2:
        print("用法: python patch_font.py <仓库根目录>")
        sys.exit(1)

    repo_root = sys.argv[1]
    patcher = FontPatcher(repo_root)
    patcher.run()


if __name__ == "__main__":
    main()