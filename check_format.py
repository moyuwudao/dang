with open('/home/mayn/dang/.flutter-plugins-dependencies', 'r') as f:
    content = f.read()

first_path_start = content.find('"path"')
if first_path_start >= 0:
    snippet = content[first_path_start:first_path_start+80]
    print('Raw file snippet:', repr(snippet))
else:
    print('No path found')
