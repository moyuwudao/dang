#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
轻量级服务器管理 Agent
用于远程执行命令、管理文件和监控状态
"""

import os
import sys
import json
import time
import hmac
import hashlib
import subprocess
import logging
from datetime import datetime
from functools import wraps
from flask import Flask, request, jsonify

# 配置
AGENT_PORT = 8848
AGENT_TOKEN = "changji-agent-2026"  # 生产环境应使用更复杂的Token
AGENT_VERSION = "1.0.0"
ALLOWED_IPS = ["127.0.0.1"]  # 允许访问的IP列表

# 日志配置
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/server-agent.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)


def verify_token(f):
    """Token认证装饰器"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('X-Agent-Token')
        if not token:
            return jsonify({"error": "缺少认证Token"}), 401
        if token != AGENT_TOKEN:
            logger.warning(f"无效的Token尝试: {request.remote_addr}")
            return jsonify({"error": "无效的Token"}), 403
        return f(*args, **kwargs)
    return decorated_function


def check_ip(f):
    """IP白名单检查装饰器"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        client_ip = request.remote_addr
        if client_ip not in ALLOWED_IPS:
            logger.warning(f"未授权的IP访问: {client_ip}")
            return jsonify({"error": "未授权的IP地址"}), 403
        return f(*args, **kwargs)
    return decorated_function


@app.route('/health', methods=['GET'])
def health_check():
    """健康检查接口"""
    return jsonify({
        "status": "healthy",
        "version": AGENT_VERSION,
        "timestamp": datetime.now().isoformat()
    })


@app.route('/info', methods=['GET'])
@verify_token
def system_info():
    """获取系统信息"""
    try:
        # CPU信息
        cpu_info = subprocess.run(['cat', '/proc/cpuinfo'], 
                                capture_output=True, text=True)
        cpu_count = subprocess.run(['nproc'], 
                                 capture_output=True, text=True)
        
        # 内存信息
        mem_info = subprocess.run(['free', '-h'], 
                                capture_output=True, text=True)
        
        # 磁盘信息
        disk_info = subprocess.run(['df', '-h'], 
                                 capture_output=True, text=True)
        
        # 负载信息
        load_info = subprocess.run(['uptime'], 
                                 capture_output=True, text=True)
        
        # 服务状态
        services = ['ssh', 'nginx', 'docker', 'postgresql', 'redis-server', 
                   'fail2ban', 'unattended-upgrades', 'chrony']
        service_status = {}
        for service in services:
            result = subprocess.run(['systemctl', 'is-active', service], 
                                  capture_output=True, text=True)
            service_status[service] = result.stdout.strip()
        
        return jsonify({
            "status": "success",
            "timestamp": datetime.now().isoformat(),
            "cpu_cores": cpu_count.stdout.strip(),
            "memory": mem_info.stdout,
            "disk": disk_info.stdout,
            "load": load_info.stdout.strip(),
            "services": service_status
        })
    except Exception as e:
        logger.error(f"获取系统信息失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/execute', methods=['POST'])
@verify_token
def execute_command():
    """执行命令"""
    try:
        data = request.get_json()
        if not data or 'command' not in data:
            return jsonify({"error": "缺少命令参数"}), 400
        
        command = data['command']
        timeout = data.get('timeout', 30)
        
        logger.info(f"执行命令: {command}")
        
        # 执行命令
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        
        return jsonify({
            "status": "success",
            "command": command,
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "timestamp": datetime.now().isoformat()
        })
    except subprocess.TimeoutExpired:
        logger.error(f"命令执行超时: {command}")
        return jsonify({"error": "命令执行超时"}), 408
    except Exception as e:
        logger.error(f"命令执行失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/file/read', methods=['POST'])
@verify_token
def read_file():
    """读取文件"""
    try:
        data = request.get_json()
        if not data or 'path' not in data:
            return jsonify({"error": "缺少文件路径"}), 400
        
        file_path = data['path']
        
        # 安全检查：禁止读取敏感文件
        forbidden_paths = ['/etc/shadow', '/etc/passwd', '/root/.ssh']
        if any(file_path.startswith(fp) for fp in forbidden_paths):
            return jsonify({"error": "禁止访问该文件"}), 403
        
        if not os.path.exists(file_path):
            return jsonify({"error": "文件不存在"}), 404
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        return jsonify({
            "status": "success",
            "path": file_path,
            "content": content,
            "size": len(content),
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"读取文件失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/file/write', methods=['POST'])
@verify_token
def write_file():
    """写入文件"""
    try:
        data = request.get_json()
        if not data or 'path' not in data or 'content' not in data:
            return jsonify({"error": "缺少路径或内容参数"}), 400
        
        file_path = data['path']
        content = data['content']
        mode = data.get('mode', 'w')
        
        # 创建目录（如果不存在）
        dir_path = os.path.dirname(file_path)
        if dir_path and not os.path.exists(dir_path):
            os.makedirs(dir_path)
        
        with open(file_path, mode, encoding='utf-8') as f:
            f.write(content)
        
        logger.info(f"写入文件: {file_path}")
        
        return jsonify({
            "status": "success",
            "path": file_path,
            "size": len(content),
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"写入文件失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/services', methods=['GET'])
@verify_token
def list_services():
    """列出所有服务状态"""
    try:
        services = ['ssh', 'nginx', 'docker', 'postgresql', 'redis-server', 
                   'fail2ban', 'unattended-upgrades', 'chrony', 'ufw']
        service_status = {}
        
        for service in services:
            try:
                result = subprocess.run(['systemctl', 'is-active', service], 
                                      capture_output=True, text=True)
                status = result.stdout.strip()
                
                # 获取服务详细信息
                info_result = subprocess.run(['systemctl', 'show', service, 
                                            '--property=Description,MainPID,MemoryCurrent,CPUUsageNSec'], 
                                           capture_output=True, text=True)
                
                service_status[service] = {
                    "status": status,
                    "info": info_result.stdout
                }
            except:
                service_status[service] = {"status": "unknown"}
        
        return jsonify({
            "status": "success",
            "services": service_status,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"获取服务列表失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/service/control', methods=['POST'])
@verify_token
def control_service():
    """控制服务（启动/停止/重启）"""
    try:
        data = request.get_json()
        if not data or 'service' not in data or 'action' not in data:
            return jsonify({"error": "缺少服务名或操作参数"}), 400
        
        service = data['service']
        action = data['action']
        
        # 只允许特定的操作
        allowed_actions = ['start', 'stop', 'restart', 'status', 'enable', 'disable']
        if action not in allowed_actions:
            return jsonify({"error": "不允许的操作"}), 400
        
        logger.info(f"服务控制: {service} {action}")
        
        result = subprocess.run(['sudo', 'systemctl', action, service], 
                              capture_output=True, text=True)
        
        return jsonify({
            "status": "success",
            "service": service,
            "action": action,
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"服务控制失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/logs', methods=['POST'])
@verify_token
def get_logs():
    """获取日志"""
    try:
        data = request.get_json()
        if not data or 'service' not in data:
            return jsonify({"error": "缺少服务参数"}), 400
        
        service = data['service']
        lines = data.get('lines', 50)
        
        log_paths = {
            'ssh': '/var/log/auth.log',
            'nginx': '/var/log/nginx/error.log',
            'postgresql': '/var/log/postgresql/postgresql-14-main.log',
            'redis': '/var/log/redis/redis-server.log',
            'system': '/var/log/syslog',
            'agent': '/var/log/server-agent.log'
        }
        
        if service not in log_paths:
            return jsonify({"error": "未知的服务日志"}), 400
        
        log_path = log_paths[service]
        
        if not os.path.exists(log_path):
            return jsonify({"error": "日志文件不存在"}), 404
        
        # 使用tail获取最后N行
        result = subprocess.run(['tail', '-n', str(lines), log_path], 
                              capture_output=True, text=True)
        
        return jsonify({
            "status": "success",
            "service": service,
            "path": log_path,
            "lines": lines,
            "content": result.stdout,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"获取日志失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/backup', methods=['POST'])
@verify_token
def trigger_backup():
    """触发备份"""
    try:
        result = subprocess.run(['sudo', '/backup/scripts/backup.sh'], 
                              capture_output=True, text=True, timeout=300)
        
        return jsonify({
            "status": "success",
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"触发备份失败: {str(e)}")
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    logger.info(f"启动 Server Agent v{AGENT_VERSION} on port {AGENT_PORT}")
    
    # 确保日志目录存在
    os.makedirs('/var/log', exist_ok=True)
    
    # 启动服务（仅允许本地访问，生产环境建议使用Nginx反向代理）
    app.run(host='127.0.0.1', port=AGENT_PORT, debug=False)
