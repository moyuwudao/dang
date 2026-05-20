#!/usr/bin/env python3
"""
通义听悟离线转写测试脚本
测试流程：
1. 创建离线转写任务（使用本地音频文件）
2. 查询任务状态
3. 获取转写结果
"""

import base64
import hashlib
import hmac
import json
import time
import uuid
from datetime import datetime, timezone
from urllib.parse import quote

# 从环境变量读取凭证
import os

ACCESS_KEY_ID = os.environ.get('ALIBABA_ACCESS_KEY_ID', '')
ACCESS_KEY_SECRET = os.environ.get('ALIBABA_ACCESS_KEY_SECRET', '')
APP_KEY = os.environ.get('TINGWU_APP_KEY', '')

if not all([ACCESS_KEY_ID, ACCESS_KEY_SECRET, APP_KEY]):
    print("错误: 请设置环境变量 ALIBABA_ACCESS_KEY_ID, ALIBABA_ACCESS_KEY_SECRET, TINGWU_APP_KEY")
    exit(1)

# 音频文件路径
AUDIO_FILE = r"C:\Users\Mayn\Downloads\backup_1779071705220\recording_1778953588269.wav"

def get_gmt_time():
    """获取 GMT 格式时间"""
    return datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S GMT')

def percent_encode(value):
    """URL 编码（阿里云规范）"""
    encoded = quote(str(value), safe='')
    encoded = encoded.replace('+', '%20')
    encoded = encoded.replace('*', '%2A')
    encoded = encoded.replace('%7E', '~')
    return encoded

def sign_request(access_key_id, access_key_secret, method, path, query_params=None, body=None):
    """阿里云 V2 ROA 签名"""
    now = get_gmt_time()
    nonce = str(uuid.uuid4())

    # Content-MD5
    if body:
        content_md5 = base64.b64encode(hashlib.md5(body.encode('utf-8')).digest()).decode('utf-8')
    else:
        content_md5 = ''

    content_type = 'application/json'
    api_version = '2023-09-30'

    # Canonicalized Headers
    headers = {
        'x-acs-signature-method': 'HMAC-SHA1',
        'x-acs-signature-nonce': nonce,
        'x-acs-signature-version': '1.0',
        'x-acs-version': api_version,
    }
    sorted_keys = sorted(headers.keys(), key=lambda x: x.lower())
    canonicalized_headers = ''.join(f"{k.lower()}:{headers[k]}\n" for k in sorted_keys)

    # Canonicalized Resource
    if query_params:
        sorted_qkeys = sorted(query_params.keys())
        pairs = [f"{percent_encode(k)}={percent_encode(query_params[k])}" for k in sorted_qkeys]
        canonicalized_resource = f"{path}?{'&'.join(pairs)}"
    else:
        canonicalized_resource = path

    # StringToSign
    string_to_sign = f"{method}\napplication/json\n{content_md5}\n{content_type}\n{now}\n{canonicalized_headers}{canonicalized_resource}"

    # Signature
    key = access_key_secret.encode('utf-8')
    signature = base64.b64encode(
        hmac.new(key, string_to_sign.encode('utf-8'), hashlib.sha1).digest()
    ).decode('utf-8')

    authorization = f"acs {access_key_id}:{signature}"

    return {
        'Authorization': authorization,
        'Date': now,
        'Content-MD5': content_md5,
        'Content-Type': content_type,
        'x-acs-signature-method': 'HMAC-SHA1',
        'x-acs-signature-nonce': nonce,
        'x-acs-signature-version': '1.0',
        'x-acs-version': api_version,
        'Accept': 'application/json',
    }

def create_task():
    """创建离线转写任务"""
    print("=" * 60)
    print("步骤 1: 创建离线转写任务")
    print("=" * 60)

    # 读取音频文件
    with open(AUDIO_FILE, 'rb') as f:
        audio_bytes = f.read()

    print(f"音频文件大小: {len(audio_bytes)} bytes")

    # 将音频转为 Base64
    audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
    print(f"Base64 长度: {len(audio_base64)}")

    # 构建请求体
    body = {
        'AppKey': APP_KEY,
        'Input': {
            'FileUrl': f"data:audio/wav;base64,{audio_base64}",
            'SourceLanguage': 'cn',
            'TaskKey': f'test_{int(time.time() * 1000)}',
        },
        'Parameters': {
            'Transcription': {
                'DiarizationEnabled': True,
                'Diarization': {
                    'SpeakerCount': 0,
                },
            },
        },
    }

    body_json = json.dumps(body)
    print(f"请求体大小: {len(body_json)} bytes")

    # 签名
    path = '/openapi/tingwu/v2/tasks'
    query_params = {'type': 'offline'}
    headers = sign_request(ACCESS_KEY_ID, ACCESS_KEY_SECRET, 'PUT', path, query_params, body_json)

    # 发送请求
    import urllib.request
    import urllib.error

    url = f"https://tingwu.cn-beijing.aliyuncs.com{path}?type=offline"
    req = urllib.request.Request(url, method='PUT')
    for k, v in headers.items():
        req.add_header(k, v)
    req.data = body_json.encode('utf-8')

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            response = json.loads(resp.read().decode('utf-8'))
            print(f"\n✅ 任务创建成功!")
            print(f"响应: {json.dumps(response, indent=2, ensure_ascii=False)}")
            task_id = response.get('Data', {}).get('TaskId')
            print(f"\nTaskId: {task_id}")
            return task_id
    except urllib.error.HTTPError as e:
        print(f"\n❌ HTTP 错误: {e.code}")
        print(f"响应: {e.read().decode('utf-8')}")
        return None
    except Exception as e:
        print(f"\n❌ 请求失败: {e}")
        return None

def query_task(task_id):
    """查询任务状态"""
    print(f"\n{'=' * 60}")
    print(f"步骤 2: 查询任务状态 (TaskId: {task_id})")
    print("=" * 60)

    path = f'/openapi/tingwu/v2/tasks/{task_id}'
    headers = sign_request(ACCESS_KEY_ID, ACCESS_KEY_SECRET, 'GET', path)

    import urllib.request
    import urllib.error

    url = f"https://tingwu.cn-beijing.aliyuncs.com{path}"
    req = urllib.request.Request(url, method='GET')
    for k, v in headers.items():
        req.add_header(k, v)

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            response = json.loads(resp.read().decode('utf-8'))
            task_data = response.get('Data', {})
            task_status = task_data.get('TaskStatus', 'UNKNOWN')
            print(f"任务状态: {task_status}")

            if task_status == 'SUCCESS':
                result_url = task_data.get('Result')
                print(f"结果 URL: {result_url}")
                return result_url
            elif task_status == 'FAILED':
                error_msg = task_data.get('ErrorMessage', 'Unknown error')
                print(f"任务失败: {error_msg}")
                return None
            else:
                return None
    except Exception as e:
        print(f"查询失败: {e}")
        return None

def download_result(result_url):
    """下载转写结果"""
    print(f"\n{'=' * 60}")
    print("步骤 3: 下载转写结果")
    print("=" * 60)

    import urllib.request

    try:
        req = urllib.request.Request(result_url)
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = resp.read().decode('utf-8')
            print(f"结果内容:\n{result[:2000]}...")
            return result
    except Exception as e:
        print(f"下载失败: {e}")
        return None

def main():
    print("通义听悟离线转写测试")
    print(f"音频文件: {AUDIO_FILE}")
    print(f"AppKey: {APP_KEY}")

    # 步骤 1: 创建任务
    task_id = create_task()
    if not task_id:
        print("\n❌ 测试失败: 无法创建任务")
        return

    # 步骤 2: 轮询查询任务状态
    print("\n等待任务完成...")
    max_wait = 300  # 最多等待 5 分钟
    interval = 5
    start_time = time.time()

    while time.time() - start_time < max_wait:
        result_url = query_task(task_id)
        if result_url:
            # 步骤 3: 下载结果
            download_result(result_url)
            print("\n✅ 测试完成!")
            return
        elif result_url is None:
            # 任务失败
            print("\n❌ 测试失败: 任务执行失败")
            return

        print(f"任务进行中... ({int(time.time() - start_time)}s)")
        time.sleep(interval)

    print("\n⏰ 测试超时")

if __name__ == '__main__':
    main()
