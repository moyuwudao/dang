import requests
import json

# Login
r = requests.post('http://127.0.0.1:3000/api/v1/auth/login', json={
    'phone': '13800138001',
    'password': 'ChangJi@2026#Admin!'
})
token = r.json()['data']['accessToken']
print('Login OK')

# Test healthy-models
r2 = requests.get('http://127.0.0.1:3000/api/v1/api-key/admin/healthy-models', headers={
    'Authorization': f'Bearer {token}'
})
print(f'HealthyModels: {r2.status_code}')
print(r2.text[:500])
