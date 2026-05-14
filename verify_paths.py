import json

filepath = '/home/mayn/dang/.flutter-plugins-dependencies'
with open(filepath, 'r') as f:
    d = json.load(f)

android_plugins = d.get('plugins', {}).get('android', [])
if android_plugins:
    print('Sample android plugin path:', android_plugins[0].get('path', 'N/A'))
else:
    print('No android plugins found')

has_windows_path = json.dumps(d).find('C:\\') >= 0
print(f'Has Windows paths: {has_windows_path}')
