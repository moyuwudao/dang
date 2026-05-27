import requests
import json

BASE = 'http://101.133.238.249/api/v1'
TOKEN = None
results = []

def test(name, method, path, data=None, expected=200):
    global TOKEN
    url = f'{BASE}{path}'
    headers = {'Content-Type': 'application/json'}
    if TOKEN:
        headers['Authorization'] = f'Bearer {TOKEN}'
    try:
        if method == 'GET':
            r = requests.get(url, headers=headers, timeout=10)
        elif method == 'POST':
            r = requests.post(url, headers=headers, json=data, timeout=10)
        elif method == 'PUT':
            r = requests.put(url, headers=headers, json=data, timeout=10)
        elif method == 'DELETE':
            r = requests.delete(url, headers=headers, timeout=10)
        ok = r.status_code == expected
        results.append((name, r.status_code, ok, r.text[:100] if not ok else ''))
        return r.json() if ok else None
    except Exception as e:
        results.append((name, 'ERR', False, str(e)))
        return None

# 1. 登录
test('登录', 'POST', '/auth/login', {'phone':'13800138001','password':'ChangJi@2026#Admin!'})
# 获取token
r = requests.post(f'{BASE}/auth/login', json={'phone':'13800138001','password':'ChangJi@2026#Admin!'})
if r.status_code == 200:
    TOKEN = r.json()['data']['accessToken']
    results.append(('登录获取Token', 200, True, ''))
else:
    results.append(('登录获取Token', r.status_code, False, r.text[:100]))

if not TOKEN:
    print('登录失败，无法继续测试')
    for name, code, ok, detail in results:
        status = '✅' if ok else '❌'
        print(f'{status} {name}: {code} {detail}')
    exit(1)

# 2. 仪表盘
test('仪表盘统计', 'GET', '/admin/stats')

# 3. 用户管理
test('用户列表', 'GET', '/admin/users')
test('用户详情', 'GET', '/admin/users/8ea73580-c6f3-4fe0-81db-a5e2febfbe14')

# 4. 套餐管理
test('套餐列表', 'GET', '/admin/plans')
test('订阅套餐列表', 'GET', '/subscription/plans')

# 5. API Key管理
test('API Key列表', 'GET', '/api-key/admin/list')
test('API Key统计', 'GET', '/api-key/admin/stats')
test('健康模型列表', 'GET', '/api-key/admin/healthy-models')

# 6. 订阅管理
test('订阅列表', 'GET', '/admin/subscriptions')
test('充值记录', 'GET', '/admin/recharge-records')
test('API使用日志', 'GET', '/admin/api-usage-logs')
test('收入统计', 'GET', '/admin/revenue-stats')

# 7. 监控
test('系统信息', 'GET', '/monitor/system')
test('服务状态', 'GET', '/monitor/services')
test('命令执行', 'POST', '/monitor/execute', {'command':'pm2 list --no-color','timeout':30})
test('日志查看', 'POST', '/monitor/logs', {'service':'nginx','lines':10})

# 8. API系数配置
test('套餐API策略', 'GET', '/subscription/plans/8befd02c-507d-4988-afb8-bbdefc5bb3c3/policies')

# 打印结果
print('\n' + '='*60)
print('完整测试结果')
print('='*60)
passed = 0
failed = 0
for name, code, ok, detail in results:
    status = '✅' if ok else '❌'
    if ok:
        passed += 1
    else:
        failed += 1
    detail_str = f' | {detail}' if detail else ''
    print(f'{status} {name}: {code}{detail_str}')

print(f'\n总计: {passed} 通过, {failed} 失败')
