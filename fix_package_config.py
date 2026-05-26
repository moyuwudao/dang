import json
import os
import yaml

pub_cache = "/home/mayn/.pub-cache/hosted/pub.flutter-io.cn"

# 读取 pubspec.yaml
with open('/home/mayn/dang/pubspec.yaml', 'r') as f:
    pubspec = yaml.safe_load(f)

project_name = pubspec.get('name', 'dang')
dependencies = pubspec.get('dependencies', {})
dev_dependencies = pubspec.get('dev_dependencies', {})

packages = []
package_names = set()

# 添加项目本身
packages.append({
    "name": project_name,
    "rootUri": "../",
    "packageUri": "lib/",
    "languageVersion": "3.7"
})
package_names.add(project_name)

# 添加 Flutter SDK
packages.append({
    "name": "flutter",
    "rootUri": "file:///home/mayn/flutter/packages/flutter",
    "packageUri": "lib/",
    "languageVersion": "3.7"
})
package_names.add("flutter")

# 添加 flutter_test
packages.append({
    "name": "flutter_test",
    "rootUri": "file:///home/mayn/flutter/packages/flutter_test",
    "packageUri": "lib/",
    "languageVersion": "3.7"
})
package_names.add("flutter_test")

# 添加 sky_engine
packages.append({
    "name": "sky_engine",
    "rootUri": "file:///home/mayn/flutter/bin/cache/pkg/sky_engine",
    "packageUri": "lib/",
    "languageVersion": "3.7"
})
package_names.add("sky_engine")

# 处理依赖
for dep_name in list(dependencies.keys()) + list(dev_dependencies.keys()):
    if dep_name in package_names:
        continue
    
    # 查找版本目录
    dirs = [d for d in os.listdir(pub_cache) if d.startswith(dep_name + "-")]
    if dirs:
        version_dir = sorted(dirs)[-1]
        package_dir = os.path.join(pub_cache, version_dir)
        
        packages.append({
            "name": dep_name,
            "rootUri": f"file://{package_dir}",
            "packageUri": "lib/",
            "languageVersion": "3.7"
        })
        package_names.add(dep_name)

# 构建 package_config.json
config = {
    "configVersion": 2,
    "packages": packages,
    "generated": "2026-01-01T00:00:00.000000Z",
    "generator": "pub",
    "generatorVersion": "3.11.5"
}

with open("/home/mayn/dang/.dart_tool/package_config.json", "w") as f:
    json.dump(config, f, indent=2)

print(f"Fixed package_config.json with {len(packages)} packages")
print(f"Project name: {project_name}")
