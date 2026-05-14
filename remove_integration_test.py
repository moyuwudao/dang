import json

filepath = '/home/mayn/dang/.flutter-plugins-dependencies'
with open(filepath, 'r') as f:
    data = json.load(f)

for platform in data.get('plugins', {}):
    plugins = data['plugins'][platform]
    data['plugins'][platform] = [p for p in plugins if p.get('name') != 'integration_test']

data['dependencyGraph'] = [d for d in data.get('dependencyGraph', []) if d.get('name') != 'integration_test']

with open(filepath, 'w') as f:
    json.dump(data, f)

print('integration_test removed from plugin dependencies')
