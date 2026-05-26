import requests
r = requests.post('http://127.0.0.1:8848/execute', headers={'X-Agent-Token': 'changji-agent-2026'}, json={'command': 'pm2 list --no-color', 'timeout': 30})
print(r.status_code)
print(r.text[:500])
