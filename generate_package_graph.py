import json
import os

# 读取 package_config.json
with open('/home/mayn/dang/.dart_tool/package_config.json', 'r') as f:
    config = json.load(f)

# 构建 package_graph.json
graph = {}
for pkg in config.get('packages', []):
    name = pkg['name']
    graph[name] = {
        'version': '0.0.0',
        'dependencies': []
    }

with open('/home/mayn/dang/.dart_tool/package_graph.json', 'w') as f:
    json.dump(graph, f, indent=2)

print(f"Generated package_graph.json with {len(graph)} packages")
