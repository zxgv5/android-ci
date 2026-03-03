#!/usr/bin/env python3
"""
Usage: python3 patch_rfidtools_gradle.py.py <path-to-build.gradle>
Modifies the given build.gradle file to:
- Insert signingConfigs block inside android block.
- Add signingConfig reference to release build type.
- Add ndk abiFilters "arm64-v8a" inside defaultConfig.
"""
import sys
import re

def get_indent(line):
    """Return the leading whitespace of a line."""
    return re.match(r'^\s*', line).group()

def modify_build_gradle(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    # Step 1: Insert signingConfigs after the 'android {' line
    new_lines = []
    android_inserted = False
    android_indent = None
    for line in lines:
        new_lines.append(line)
        if not android_inserted and re.match(r'^\s*android\s*\{\s*$', line):
            android_indent = get_indent(line)
            # Insert signingConfigs block with appropriate indentation (android_indent + 4 spaces)
            new_lines.append(f'{android_indent}    signingConfigs {{\n')
            new_lines.append(f'{android_indent}        release {{\n')
            new_lines.append(f'{android_indent}            storeFile file(project.property("KEYSTORE_FILE"))\n')
            new_lines.append(f'{android_indent}            storePassword project.property("KEYSTORE_PASSWORD")\n')
            new_lines.append(f'{android_indent}            keyAlias project.property("KEY_ALIAS")\n')
            new_lines.append(f'{android_indent}            keyPassword project.property("KEY_ALIAS_PASSWORD")\n')
            new_lines.append(f'{android_indent}        }}\n')
            new_lines.append(f'{android_indent}    }}\n')
            android_inserted = True
    # Step 2: Insert signingConfig reference inside release block (only in buildTypes)
    release_inserted = False
    in_build_types = False
    build_types_depth = 0
    final_lines = []
    for line in new_lines:
        final_lines.append(line)
        # Detect buildTypes block
        if re.match(r'^\s*buildTypes\s*\{\s*$', line):
            in_build_types = True
            build_types_depth = 1
        elif in_build_types:
            build_types_depth += line.count('{') - line.count('}')
            if build_types_depth <= 0:
                in_build_types = False
        if in_build_types and not release_inserted and re.match(r'^\s*release\s*\{\s*$', line):
            release_indent = get_indent(line)
            # Insert signingConfig reference (indent = release_indent + 4 spaces)
            final_lines.append(f'{release_indent}        signingConfig signingConfigs.release\n')
            release_inserted = True
    # Step 3: Insert ndk block inside defaultConfig
    ndk_inserted = False
    defaultconfig_indent = None
    another_final = []
    for line in final_lines:
        another_final.append(line)
        if not ndk_inserted and re.match(r'^\s*defaultConfig\s*\{\s*$', line):
            defaultconfig_indent = get_indent(line)
            # Insert ndk block (indent = defaultconfig_indent + 4 spaces)
            another_final.append(f'{defaultconfig_indent}    ndk {{\n')
            another_final.append(f'{defaultconfig_indent}        abiFilters "arm64-v8a"\n')
            another_final.append(f'{defaultconfig_indent}    }}\n')
            ndk_inserted = True
    # Write back
    with open(file_path, 'w') as f:
        f.writelines(another_final)
    print(f"Successfully modified {file_path}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Error: Please provide the path to build.gradle")
        sys.exit(1)
    modify_build_gradle(sys.argv[1])