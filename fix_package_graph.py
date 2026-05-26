import json
import os

# 读取 package_config.json
with open('/home/mayn/dang/.dart_tool/package_config.json', 'r') as f:
    config = json.load(f)

# 构建正确的 package_graph.json 格式
# 格式应该是 List<dynamic>，不是 Map
graph = []
for pkg in config.get('packages', []):
    name = pkg['name']
    graph.append(name)

with open('/home/mayn/dang/.dart_tool/package_graph.json', 'w') as f:
    json.dump(graph, f, indent=2)

print(f"Fixed package_graph.json with {len(graph)} packages")
print(f"Format: List (not Map)")
