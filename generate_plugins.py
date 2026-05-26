import json
import os
import subprocess

# 获取 pub-cache 路径
pub_cache = "/home/mayn/.pub-cache/hosted/pub.flutter-io.cn"

# 读取 pubspec.yaml 获取依赖
result = subprocess.run(
    ["bash", "/home/mayn/flutter/bin/flutter", "pub", "deps", "--json"],
    capture_output=True, text=True, cwd="/home/mayn/dang"
)

try:
    deps_data = json.loads(result.stdout)
except:
    print("Failed to parse deps")
    print(result.stdout[:500])
    exit(1)

# 构建插件列表
plugins = []
for package in deps_data.get("packages", []):
    name = package.get("name")
    version = package.get("version")
    
    # 检查是否是 Flutter 插件
    plugin_dir = os.path.join(pub_cache, f"{name}-{version}")
    android_dir = os.path.join(plugin_dir, "android")
    
    if os.path.exists(android_dir):
        # 检查是否有 build.gradle 或 build.gradle.kts
        has_build = os.path.exists(os.path.join(android_dir, "build.gradle")) or \
                   os.path.exists(os.path.join(android_dir, "build.gradle.kts"))
        
        if has_build:
            plugins.append({
                "name": name,
                "path": plugin_dir,
                "dependencies": [],
                "native_build": True,
                "dev_dependency": False
            })

# 构建 flutter-plugins-dependencies 结构
data = {
    "info": "This is a generated file; do not edit or check into version control.",
    "plugins": {
        "android": plugins
    },
    "dependencyGraph": []
}

# 写入文件
with open("/home/mayn/dang/.flutter-plugins-dependencies", "w") as f:
    json.dump(data, f, indent=2)

print(f"Generated .flutter-plugins-dependencies with {len(plugins)} plugins")
for p in plugins[:5]:
    print(f"  - {p['name']}: {p['path']}")
