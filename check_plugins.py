import json

try:
    with open('/home/mayn/dang/.flutter-plugins-dependencies', 'r') as f:
        data = json.load(f)
    
    deps = data.get('plugins', {}).get('dependencies', [])
    for dep in deps[:3]:
        print(f"Plugin: {dep.get('name')}")
        print(f"Path: {dep.get('path')}")
        print()
except Exception as e:
    print(f"Error: {e}")
