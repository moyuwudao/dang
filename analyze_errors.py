#!/usr/bin/env python3
"""
分析 Flutter 项目中的编译错误
"""

import os
import re
from pathlib import Path

def find_dart_files():
    """找到所有 dart 文件"""
    lib_dir = Path("/mnt/d/trae_projects/dang/lib")
    return list(lib_dir.rglob("*.dart"))

def check_import_errors():
    """检查导入错误"""
    issues = []
    
    for dart_file in find_dart_files():
        content = dart_file.read_text(encoding='utf-8')
        rel_path = str(dart_file).replace("/mnt/d/trae_projects/dang/", "")
        
        # 检查是否使用了 StateNotifier（在 riverpod 2.x 中已弃用）
        if 'StateNotifier' in content and 'extends StateNotifier' in content:
            issues.append(f"[DEPRECATED] {rel_path}: 使用了已弃用的 StateNotifier")
        
        if 'StateNotifierProvider' in content:
            issues.append(f"[DEPRECATED] {rel_path}: 使用了已弃用的 StateNotifierProvider")
        
        if 'ChangeNotifierProvider' in content:
            issues.append(f"[DEPRECATED] {rel_path}: 使用了已弃用的 ChangeNotifierProvider")
    
    return issues

def main():
    print("=== Flutter 项目错误分析 ===\n")
    
    issues = check_import_errors()
    
    print(f"发现 {len(issues)} 个问题:\n")
    
    deprecated = [i for i in issues if '[DEPRECATED]' in i]
    other = [i for i in issues if '[DEPRECATED]' not in i]
    
    if deprecated:
        print("--- 弃用 API 警告 (不会导致编译失败，但建议修复) ---")
        for issue in deprecated:
            print(issue)
        print()
    
    if other:
        print("--- 其他问题 ---")
        for issue in other:
            print(issue)
        print()
    
    print("\n=== 分析完成 ===")
    print(f"总计: {len(issues)} 个问题")
    print(f"  - 弃用 API: {len(deprecated)} 个")
    print(f"  - 其他: {len(other)} 个")

if __name__ == "__main__":
    main()
