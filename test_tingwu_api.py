#!/usr/bin/env python3
"""
通义听悟 API 本地测试脚本

测试流程：
1. 验证签名算法（PUT 测试）
2. 创建离线转写任务（需要公开可访问的音频文件 URL）
3. 查询任务状态
4. 获取转写结果

使用方法：
  python3 test_tingwu_api.py --ak-id YOUR_ACCESS_KEY_ID --ak-secret YOUR_ACCESS_KEY_SECRET --app-key YOUR_APP_KEY --file-url "https://your-bucket.oss-cn-beijing.aliyuncs.com/test.mp3"

如果只测试签名（不需要文件）：
  python3 test_tingwu_api.py --ak-id YOUR_ACCESS_KEY_ID --ak-secret YOUR_ACCESS_KEY_SECRET --app-key YOUR_APP_KEY --test-sign-only
"""

import argparse
import base64
import hashlib
import hmac
import json
import sys
import time
import uuid
from datetime import datetime, timezone
from urllib.parse import quote

import urllib.request
import urllib.error


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
    """
    阿里云 V2 ROA 签名
    """
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


def http_request(method, url, headers, body=None):
    """发送 HTTP 请求"""
    req = urllib.request.Request(url, method=method)
    for k, v in headers.items():
        req.add_header(k, v)

    if body:
        req.data = body.encode('utf-8')

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, resp.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode('utf-8')
    except Exception as e:
        return -1, str(e)


def test_signature_only(access_key_id, access_key_secret, app_key):
    """仅测试签名（不需要文件 URL）"""
    print("=" * 60)
    print("测试 1: 签名验证（PUT 不带 FileUrl，预期返回 400）")
    print("=" * 60)

    base_url = 'https://tingwu.cn-beijing.aliyuncs.com'
    path = '/openapi/tingwu/v2/tasks'
    query_params = {'type': 'offline'}

    body = json.dumps({
        'AppKey': app_key,
        'Input': {
            'SourceLanguage': 'cn',
            'TaskKey': f'test_{int(time.time() * 1000)}',
        },
    })

    headers = sign_request(access_key_id, access_key_secret, 'PUT', path, query_params, body)
    url = f"{base_url}{path}?type=offline"

    print(f"请求 URL: {url}")
    print(f"请求头:")
    for k, v in headers.items():
        print(f"  {k}: {v}")
    print(f"请求体: {body}")

    status, response = http_request('PUT', url, headers, body)

    print(f"\n响应状态: {status}")
    print(f"响应内容: {response}")

    if status == 400:
        print("\n✅ 签名验证通过！（400 表示签名正确，但缺少 FileUrl）")
        return True
    elif status == 403:
        print("\n❌ 签名错误（403）- 请检查 AccessKey ID/Secret")
        return False
    elif status == 404:
        print("\n❌ 端点不存在（404）- 请检查 URL 路径")
        return False
    else:
        print(f"\n⚠️ 意外状态码: {status}")
        return False


def submit_task(access_key_id, access_key_secret, app_key, file_url):
    """提交离线转写任务"""
    print("\n" + "=" * 60)
    print("测试 2: 创建离线转写任务")
    print("=" * 60)

    base_url = 'https://tingwu.cn-beijing.aliyuncs.com'
    path = '/openapi/tingwu/v2/tasks'
    query_params = {'type': 'offline'}

    body = json.dumps({
        'AppKey': app_key,
        'Input': {
            'FileUrl': file_url,
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
            'Summarization': {
                'Types': ['Paragraph', 'Conversational', 'QuestionsAnswering', 'Chapter'],
            },
            'MeetingAssistance': {
                'Types': ['Actions', 'KeyInformation'],
            },
        },
    })

    headers = sign_request(access_key_id, access_key_secret, 'PUT', path, query_params, body)
    url = f"{base_url}{path}?type=offline"

    print(f"请求 URL: {url}")
    print(f"请求体: {body}")

    status, response = http_request('PUT', url, headers, body)

    print(f"\n响应状态: {status}")
    print(f"响应内容: {response}")

    if status == 200 or status == 201:
        data = json.loads(response)
        task_id = data.get('Data', {}).get('TaskId')
        print(f"\n✅ 任务创建成功！TaskId: {task_id}")
        return task_id
    else:
        print(f"\n❌ 任务创建失败")
        return None


def query_task(access_key_id, access_key_secret, task_id):
    """查询任务状态"""
    print(f"\n{'=' * 60}")
    print(f"测试 3: 查询任务状态 (TaskId: {task_id})")
    print("=" * 60)

    base_url = 'https://tingwu.cn-beijing.aliyuncs.com'
    path = f'/openapi/tingwu/v2/tasks/{task_id}'

    headers = sign_request(access_key_id, access_key_secret, 'GET', path)
    url = f"{base_url}{path}"

    print(f"请求 URL: {url}")

    status, response = http_request('GET', url, headers)

    print(f"\n响应状态: {status}")
    print(f"响应内容: {response}")

    if status == 200:
        data = json.loads(response)
        task_data = data.get('Data', {})
        task_status = task_data.get('TaskStatus', 'UNKNOWN')
        print(f"\n任务状态: {task_status}")
        return task_status, task_data
    else:
        print(f"\n❌ 查询失败")
        return None, None


def wait_for_task(access_key_id, access_key_secret, task_id, timeout=600, interval=5):
    """等待任务完成"""
    print(f"\n{'=' * 60}")
    print(f"测试 4: 等待任务完成（最多 {timeout} 秒）")
    print("=" * 60)

    start_time = time.time()
    while time.time() - start_time < timeout:
        status, task_data = query_task(access_key_id, access_key_secret, task_id)

        if status == 'SUCCESS':
            print("\n✅ 任务完成！")
            result_url = task_data.get('Result')
            if result_url:
                print(f"结果 URL: {result_url}")
                # 下载结果
                print("\n正在下载结果...")
                try:
                    req = urllib.request.Request(result_url)
                    with urllib.request.urlopen(req, timeout=30) as resp:
                        result_content = resp.read().decode('utf-8')
                        print(f"结果内容:\n{result_content[:2000]}...")
                except Exception as e:
                    print(f"下载结果失败: {e}")
            return True
        elif status == 'FAILED':
            print(f"\n❌ 任务失败: {task_data.get('ErrorMessage', 'Unknown error')}")
            return False

        print(f"任务进行中... ({int(time.time() - start_time)}s elapsed)")
        time.sleep(interval)

    print("\n⏰ 任务超时")
    return False


def main():
    parser = argparse.ArgumentParser(description='通义听悟 API 测试工具')
    parser.add_argument('--ak-id', required=True, help='阿里云 AccessKey ID')
    parser.add_argument('--ak-secret', required=True, help='阿里云 AccessKey Secret')
    parser.add_argument('--app-key', required=True, help='通义听悟 AppKey')
    parser.add_argument('--file-url', help='音频文件公开 URL（可选，如果不提供则只测试签名）')
    parser.add_argument('--test-sign-only', action='store_true', help='仅测试签名，不创建任务')

    args = parser.parse_args()

    print("通义听悟 API 测试开始")
    print(f"AccessKey ID: {args.ak_id[:8]}...")
    print(f"AppKey: {args.app_key}")

    # 测试 1: 签名验证
    sign_ok = test_signature_only(args.ak_id, args.ak_secret, args.app_key)

    if not sign_ok or args.test_sign_only:
        if not sign_ok:
            print("\n❌ 签名验证失败，请检查密钥")
            sys.exit(1)
        else:
            print("\n✅ 签名验证完成")
            sys.exit(0)

    # 测试 2-4: 完整任务流程
    if not args.file_url:
        print("\n⚠️ 未提供 --file-url，跳过任务创建测试")
        print("如需完整测试，请提供公开可访问的音频文件 URL")
        sys.exit(0)

    task_id = submit_task(args.ak_id, args.ak_secret, args.app_key, args.file_url)

    if not task_id:
        print("\n❌ 任务创建失败")
        sys.exit(1)

    # 等待任务完成
    success = wait_for_task(args.ak_id, args.ak_secret, task_id)

    if success:
        print("\n✅ 所有测试通过！")
        sys.exit(0)
    else:
        print("\n❌ 测试失败")
        sys.exit(1)


if __name__ == '__main__':
    main()
