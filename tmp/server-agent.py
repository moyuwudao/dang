from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)

AGENT_TOKEN = os.environ.get('AGENT_TOKEN', 'changji-agent-2026')

@app.route('/execute', methods=['POST'])
def execute_command():
    token = request.headers.get('X-Agent-Token')
    if token != AGENT_TOKEN:
        return jsonify({'error': 'Invalid token'}), 401
    
    data = request.get_json()
    command = data.get('command', '')
    timeout = data.get('timeout', 30)
    
    # 使用 admin 用户环境执行命令
    env = os.environ.copy()
    env['HOME'] = '/home/admin'
    env['USER'] = 'admin'
    env['PATH'] = '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin'
    
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
            cwd='/home/admin'
        )
        return jsonify({
            'output': result.stdout + result.stderr,
            'returncode': result.returncode
        })
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Command timeout'}), 408
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8848)
