import asyncio
import json
import base64
import wave
import websockets
import time

API_KEY = "sk-103ddf012c494f5099a10ec41f171253"
WS_URL = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen-omni-turbo-realtime"
AUDIO_FILE = "C:/Users/Mayn/Downloads/backup_1779071705220/recording_1779071025849.wav"

async def test_websocket():
    print("=" * 60)
    print("Qwen WebSocket 实时转写测试")
    print("=" * 60)
    
    # 读取音频文件
    print(f"\n读取音频文件: {AUDIO_FILE}")
    with wave.open(AUDIO_FILE, 'rb') as wav_file:
        n_channels = wav_file.getnchannels()
        sample_width = wav_file.getsampwidth()
        frame_rate = wav_file.getframerate()
        n_frames = wav_file.getnframes()
        
        print(f"  声道数: {n_channels}")
        print(f"  采样宽度: {sample_width} bytes")
        print(f"  采样率: {frame_rate} Hz")
        print(f"  总帧数: {n_frames}")
        print(f"  时长: {n_frames / frame_rate:.2f} 秒")
        
        # 读取音频数据
        audio_data = wav_file.readframes(n_frames)
        print(f"  音频数据大小: {len(audio_data)} bytes")
    
    # 连接 WebSocket
    print(f"\n连接 WebSocket: {WS_URL}")
    headers = {
        "Authorization": f"Bearer {API_KEY}"
    }
    
    async with websockets.connect(WS_URL, extra_headers=headers) as ws:
        print("  WebSocket 连接成功!")
        
        # 等待 session.created
        print("\n等待 session.created...")
        response = await ws.recv()
        data = json.loads(response)
        print(f"  收到: {data['type']}")
        
        if data['type'] == 'session.created':
            print("  ✓ session.created 收到")
            
            # 发送 session.update
            session_update = {
                "event_id": f"event_{int(time.time() * 1000)}_update",
                "type": "session.update",
                "session": {
                    "modalities": ["text"],
                    "input_audio_format": "pcm",
                }
            }
            print(f"\n发送 session.update...")
            await ws.send(json.dumps(session_update))
            
            # 等待 session.updated
            print("等待 session.updated...")
            response = await ws.recv()
            data = json.loads(response)
            print(f"  收到: {data['type']}")
            
            if data['type'] == 'session.updated':
                print("  ✓ session.updated 收到")
                
                # 发送 conversation.item.create
                conversation_item = {
                    "event_id": f"event_{int(time.time() * 1000)}_item",
                    "type": "conversation.item.create",
                    "item": {
                        "type": "message",
                        "role": "user",
                        "content": [
                            {
                                "type": "input_audio",
                                "audio": "",
                            }
                        ]
                    }
                }
                print(f"\n发送 conversation.item.create...")
                await ws.send(json.dumps(conversation_item))
                
                # 发送 response.create
                response_create = {
                    "event_id": f"event_{int(time.time() * 1000)}_response",
                    "type": "response.create",
                    "response": {
                        "modalities": ["text"],
                    }
                }
                print(f"发送 response.create...")
                await ws.send(json.dumps(response_create))
                
                # 发送音频数据
                print(f"\n发送音频数据...")
                chunk_size = 640  # 20ms @ 16kHz 16bit mono
                total_chunks = len(audio_data) // chunk_size
                print(f"  总块数: {total_chunks}")
                
                for i in range(0, len(audio_data), chunk_size):
                    chunk = audio_data[i:i + chunk_size]
                    if len(chunk) < chunk_size:
                        chunk = chunk + b'\x00' * (chunk_size - len(chunk))
                    
                    append_message = {
                        "event_id": f"event_{int(time.time() * 1000)}_audio",
                        "type": "input_audio_buffer.append",
                        "audio": base64.b64encode(chunk).decode('utf-8')
                    }
                    await ws.send(json.dumps(append_message))
                    
                    if i // chunk_size < 5 or (i // chunk_size) % 50 == 0:
                        print(f"  发送块 {i // chunk_size + 1}/{total_chunks}, 大小: {len(chunk)} bytes")
                    
                    # 模拟实时发送，每20ms发送一块
                    await asyncio.sleep(0.02)
                
                print(f"  ✓ 音频数据发送完成")
                
                # 发送 commit
                commit_message = {
                    "event_id": f"event_{int(time.time() * 1000)}_commit",
                    "type": "input_audio_buffer.commit"
                }
                print(f"\n发送 input_audio_buffer.commit...")
                await ws.send(json.dumps(commit_message))
                
                # 接收转写结果
                print(f"\n等待转写结果...")
                print("-" * 60)
                
                try:
                    while True:
                        response = await asyncio.wait_for(ws.recv(), timeout=10.0)
                        data = json.loads(response)
                        print(f"收到事件: {data['type']}")
                        
                        if data['type'] == 'error':
                            print(f"  ❌ 错误: {data.get('error', {})}")
                            break
                        elif data['type'] == 'response.audio_transcript.delta':
                            delta = data.get('delta', '')
                            print(f"  📝 转写增量: {delta}")
                        elif data['type'] == 'response.audio_transcript.done':
                            transcript = data.get('transcript', '')
                            print(f"  ✅ 转写完成: {transcript}")
                            break
                        elif data['type'] == 'response.done':
                            print(f"  ✓ 响应完成")
                            break
                        elif data['type'] == 'input_audio_buffer.speech_started':
                            print(f"  🎤 检测到语音开始")
                        elif data['type'] == 'input_audio_buffer.speech_stopped':
                            print(f"  🎤 检测到语音结束")
                        else:
                            print(f"  其他事件: {json.dumps(data, indent=2)[:200]}")
                            
                except asyncio.TimeoutError:
                    print("  ⏰ 等待超时")
                
            else:
                print(f"  ❌ 未收到 session.updated，收到: {data['type']}")
        else:
            print(f"  ❌ 未收到 session.created，收到: {data['type']}")
    
    print("\n" + "=" * 60)
    print("测试完成")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(test_websocket())
