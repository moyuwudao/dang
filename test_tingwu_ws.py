#!/usr/bin/env python3
"""
测试通义听悟 WebSocket 实时转写连接
"""

import json
import time
import uuid

def test_dashscope_ws():
    """测试 DashScope WebSocket 连接"""
    print("=" * 60)
    print("测试 DashScope WebSocket 连接")
    print("=" * 60)
    
    # 尝试不同的端点
    urls = [
        "wss://dashscope.aliyuncs.com/api-ws/v1/inference?model=tingwu-realtime",
        "wss://dashscope.aliyuncs.com/api-ws/v1/inference?model=tingwu",
    ]
    
    api_key = "YOUR_API_KEY"  # 需要替换为实际的 API Key
    
    for url in urls:
        print(f"\n测试: {url}")
        try:
            import websocket
            
            ws = websocket.create_connection(
                url,
                header={
                    "Authorization": f"bearer {api_key}"
                },
                timeout=10
            )
            print("✅ 连接成功!")
            
            # 发送开始转写请求
            start_msg = {
                "header": {
                    "action": "run-task",
                    "task_id": str(uuid.uuid4()),
                    "streaming": "duplex"
                },
                "payload": {
                    "task_group": "tingwu",
                    "task": "realtime",
                    "function": "transcription",
                    "input": {
                        "format": "wav",
                        "sample_rate": 16000,
                        "language": "zh"
                    },
                    "parameters": {
                        "diarization_enabled": True
                    }
                }
            }
            
            ws.send(json.dumps(start_msg))
            print(f"发送开始请求: {json.dumps(start_msg, indent=2)}")
            
            # 接收响应
            response = ws.recv()
            print(f"收到响应: {response}")
            
            ws.close()
            print("✅ WebSocket 测试完成!")
            return True
            
        except Exception as e:
            print(f"❌ 连接失败: {e}")
    
    return False

def test_tingwu_ws():
    """测试通义听悟原生 WebSocket"""
    print("\n" + "=" * 60)
    print("测试通义听悟原生 WebSocket")
    print("=" * 60)
    
    url = "wss://tingwu.cn-beijing.aliyuncs.com/realtime"
    print(f"\n测试: {url}")
    
    try:
        import websocket
        
        ws = websocket.create_connection(url, timeout=10)
        print("✅ 连接成功!")
        ws.close()
        return True
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        return False

if __name__ == '__main__':
    print("通义听悟 WebSocket 连接测试")
    print("注意：需要替换 YOUR_API_KEY 为实际的 API Key")
    
    # 测试 DashScope 端点
    dashscope_ok = test_dashscope_ws()
    
    # 测试原生端点
    tingwu_ok = test_tingwu_ws()
    
    print("\n" + "=" * 60)
    print("测试结果总结")
    print("=" * 60)
    print(f"DashScope 端点: {'✅ 可用' if dashscope_ok else '❌ 不可用'}")
    print(f"原生端点: {'✅ 可用' if tingwu_ok else '❌ 不可用'}")
