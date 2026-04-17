#!/usr/bin/env python3
"""
fcitx5-android 自定义字体补丁脚本 (修复 Parcelize 序列化问题)

用法:
    python patch_font.py /path/to/fcitx5-android

解决编译错误:
    Type is not directly supported by 'Parcelize'. Annotate with '@RawValue'
    Serializer has not been found for type 'Typeface?'. Use @Contextual or @Transient.
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

    def _add_params_to_data_class(
        self,
        lines: List[str],
        class_start_line: int,
        params_to_add: List[str],
    ) -> List[str]:
        """在 data class 参数列表末尾添加新参数。"""
        i = class_start_line
        while i < len(lines) and '(' not in lines[i]:
            i += 1
        if i >= len(lines):
            return lines
        open_paren_line = i

        paren_count = 0
        close_paren_line = -1
        for j in range(open_paren_line, len(lines)):
            line = lines[j]
            if '//' in line:
                line = line.split('//')[0]
            for ch in line:
                if ch == '(':
                    paren_count += 1
                elif ch == ')':
                    paren_count -= 1
                    if paren_count == 0:
                        close_paren_line = j
                        break
            if close_paren_line != -1:
                break
        if close_paren_line == -1:
            return lines

        close_line = lines[close_paren_line]
        stripped = close_line.strip()
        indent = close_line[:len(close_line) - len(close_line.lstrip())]

        if stripped == ')' or stripped.startswith(') :'):
            prev = close_paren_line - 1
            while prev >= 0 and lines[prev].strip() == '':
                prev -= 1
            if prev >= 0:
                prev_line = lines[prev]
                if not prev_line.rstrip().endswith(','):
                    lines[prev] = prev_line.rstrip() + ','
            for param in reversed(params_to_add):
                lines.insert(close_paren_line, indent + param)
        else:
            if close_line.rstrip().endswith(','):
                modified = close_line.replace(')', ', ' + ', '.join(params_to_add) + ')')
            else:
                modified = close_line.replace(')', ', ' + ', '.join(params_to_add) + ')')
            lines[close_paren_line] = modified

        return lines

    def patch_theme_file(self):
        """修改 Theme.kt，添加字体属性并处理序列化注解"""
        theme_path = "app/src/main/java/org/fcitx/fcitx5/android/data/theme/Theme.kt"
        content = self.read_file(theme_path)
        if content is None:
            return

        # 添加必需的 import
        content, _ = self.ensure_import(content, "import android.graphics.Typeface")
        content, _ = self.ensure_import(content, "import kotlinx.parcelize.RawValue")

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

        # 2. Custom data class (带 @Transient 和 @RawValue)
        custom_start = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('data class Custom('):
                custom_start = i
                break
        if custom_start != -1:
            if not any('keyTypeface' in l for l in lines[custom_start:custom_start+50]):
                params = [
                    "@Transient @RawValue override val keyTypeface: Typeface? = null,",
                    "@Transient @RawValue override val candidateTypeface: Typeface? = null"
                ]
                lines = self._add_params_to_data_class(lines, custom_start, params)

        # 3. Builtin data class (带 @Transient 和 @RawValue)
        builtin_start = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('data class Builtin('):
                builtin_start = i
                break
        if builtin_start != -1:
            if not any('keyTypeface' in l for l in lines[builtin_start:builtin_start+50]):
                params = [
                    "@Transient @RawValue override val keyTypeface: Typeface? = null,",
                    "@Transient @RawValue override val candidateTypeface: Typeface? = null"
                ]
                lines = self._add_params_to_data_class(lines, builtin_start, params)

        # 4. Monet data class (带 @Transient 和 @RawValue)
        monet_start = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('data class Monet('):
                monet_start = i
                break
        if monet_start != -1:
            if not any('keyTypeface' in l for l in lines[monet_start:monet_start+50]):
                params = [
                    "@Transient @RawValue override val keyTypeface: Typeface? = null,",
                    "@Transient @RawValue override val candidateTypeface: Typeface? = null"
                ]
                lines = self._add_params_to_data_class(lines, monet_start, params)

        self.write_file(theme_path, '\n'.join(lines))

    def patch_theme_manager_file(self):
        """修改 ThemeManager.kt"""
        tm_path = "app/src/main/java/org/fcitx/fcitx5/android/data/theme/ThemeManager.kt"
        content = self.read_file(tm_path)
        if content is None:
            return

        content, _ = self.ensure_import(content, "import android.graphics.Typeface")
        content, _ = self.ensure_import(content, "import org.fcitx.fcitx5.android.utils.appContext")

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

        if 'copy(keyTypeface = customKeyTypeface' not in content:
            content = re.sub(
                r'(val BuiltinThemes = listOf\()([\s\S]*?)(\))',
                lambda m: m.group(1) + re.sub(
                    r'(ThemePreset\.\w+)',
                    r'\1.copy(keyTypeface = customKeyTypeface, candidateTypeface = customCandidateTypeface)',
                    m.group(2)
                ) + m.group(3),
                content,
                flags=re.DOTALL
            )

        monet_init = 'private var monetThemes = listOf(ThemeMonet.getLight(), ThemeMonet.getDark())'
        if monet_init in content and 'map { it.copy' not in content:
            content = content.replace(
                monet_init,
                monet_init + '.map { it.copy(keyTypeface = customKeyTypeface, candidateTypeface = customCandidateTypeface) }'
            )

        onchange_line = 'monetThemes = listOf(ThemeMonet.getLight(), ThemeMonet.getDark())'
        if onchange_line in content and 'map { it.copy' not in content:
            content = content.replace(
                onchange_line,
                onchange_line + '.map { it.copy(keyTypeface = customKeyTypeface, candidateTypeface = customCandidateTypeface) }'
            )

        get_theme_pattern = r'(fun getTheme\(name: String\) =\s*)([^\n]+)'
        match = re.search(get_theme_pattern, content)
        if match:
            original_expr = match.group(2).strip()
            if '?.copy' not in original_expr:
                new_expr = f"{original_expr}?.copy(keyTypeface = customKeyTypeface, candidateTypeface = customCandidateTypeface)"
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