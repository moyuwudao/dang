import json
import re

filepath = '/home/mayn/dang/.flutter-plugins-dependencies'
with open(filepath, 'r') as f:
    data = json.load(f)

def fix_path(obj):
    if isinstance(obj, str):
        if 'flutter-sdk' in obj or 'flutter' in obj.lower():
            obj = re.sub(r'C:[/\\]+flutter-sdk[/\\]+', '/home/mayn/flutter/', obj)
            obj = re.sub(r'C:[/\\]+flutter-sdk[/\\]*', '/home/mayn/flutter/', obj)
            obj = obj.replace('\\', '/')
            obj = re.sub(r'/+', '/', obj)
        return obj
    elif isinstance(obj, dict):
        return {k: fix_path(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [fix_path(item) for item in obj]
    return obj

data = fix_path(data)

with open(filepath, 'w') as f:
    json.dump(data, f)

with open(filepath, 'r') as f:
    d = json.load(f)

android_plugins = d.get('plugins', {}).get('android', [])
if android_plugins:
    print('Sample path:', android_plugins[0].get('path', 'N/A'))
