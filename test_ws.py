#!/usr/bin/env python3
import json
import websocket
import time

API_KEY = 'sk-103ddf012c494f5099a10ec41f171253'
WS_URL = 'wss://dashscope.aliyuncs.com/api-ws/v1/inference/'

def generate_task_id():
    import random
    chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
    return ''.join(random.choice(chars) for _ in range(32))

print('Testing DashScope WebSocket with Fun-ASR...')
print('API Key:', API_KEY[:10] + '...')

task_id = generate_task_id()
print('Task ID:', task_id)

# 创建 WebSocket 连接
ws = websocket.create_connection(
    WS_URL,
    header=[
        f'Authorization: Bearer {API_KEY}',
    ]
)

print('Connected!')

# 发送 run-task 消息
run_task = {
    'header': {
        'action': 'run-task',
        'task_id': task_id,
        'streaming': 'duplex',
    },
    'payload': {
        'task_group': 'audio',
        'task': 'asr',
        'function': 'recognition',
        'model': 'fun-asr-realtime',
        'parameters': {
            'sample_rate': 16000,
            'format': 'wav',
        },
        'input': {},
    },
}

print('Sending run-task:', json.dumps(run_task, indent=2))
ws.send(json.dumps(run_task))

# 接收响应
start_time = time.time()
while time.time() - start_time < 10:
    try:
        ws.settimeout(5)
        message = ws.recv()
        print('Received:', message)
        
        data = json.loads(message)
        event = data.get('header', {}).get('event')
        print('Event:', event)
        
        if event == 'task-started':
            print('Task started! Sending finish-task...')
            finish_task = {
                'header': {
                    'action': 'finish-task',
                    'task_id': task_id,
                    'streaming': 'duplex',
                },
                'payload': {
                    'input': {},
                },
            }
            ws.send(json.dumps(finish_task))
        
        if event == 'task-finished':
            print('Task finished successfully!')
            break
            
        if event == 'task-failed':
            error = data.get('header', {}).get('error_message', 'Unknown error')
            print('Task failed:', error)
            break
            
    except websocket.WebSocketTimeoutException:
        print('Timeout waiting for response')
        break
    except Exception as e:
        print('Error:', e)
        break

ws.close()
print('Connection closed')
