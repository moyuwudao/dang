"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MonitorService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("@nestjs/axios");
const rxjs_1 = require("rxjs");
let MonitorService = class MonitorService {
    constructor(httpService) {
        this.httpService = httpService;
        this.agentUrl = 'http://127.0.0.1:8848';
        this.agentToken = 'changji-agent-2026';
        this.allowedCommands = [
            'cat', 'ls', 'll', 'df', 'free', 'ps', 'top', 'htop',
            'uptime', 'whoami', 'pwd', 'echo', 'date', 'uname',
            'netstat', 'ss', 'ping', 'curl', 'wget', 'grep',
            'find', 'head', 'tail', 'wc', 'sort', 'uniq',
            'vmstat', 'iostat', 'mpstat', 'sar', 'lsof',
            'systemctl status', 'service --status-all',
            'journalctl', 'dmesg', 'pm2', 'last',
        ];
        this.forbiddenPatterns = [
            'rm ', 'rm -', 'mkfs', 'dd ', 'dd if=',
            'shutdown', 'reboot', 'halt', 'poweroff', 'init 0', 'init 6',
            'kill ', 'kill -', 'pkill ', 'killall ',
            '> ', '>> ', '; ', '&& ', '|| ',
            'wget.*-O ', 'curl.*-o ', 'curl.*--output ',
            'bash ', 'sh ', 'python ', 'python3 ', 'node ',
            'eval ', 'exec ', 'source ', '. ',
        ];
    }
    async agentExecute(command, timeout = 30) {
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.agentUrl}/execute`, { command, timeout }, {
                headers: {
                    'X-Agent-Token': this.agentToken,
                    'Content-Type': 'application/json',
                },
            }));
            return response.data;
        }
        catch (error) {
            throw new common_1.HttpException(error.response?.data?.error || 'Agent request failed', error.response?.status || 500);
        }
    }
    async getSystemInfo() {
        const [memResult, diskResult, loadResult, cpuResult] = await Promise.all([
            this.agentExecute('free -h'),
            this.agentExecute('df -h /'),
            this.agentExecute('uptime'),
            this.agentExecute('nproc'),
        ]);
        const memOutput = memResult.output || '';
        const diskOutput = diskResult.output || '';
        const loadOutput = loadResult.output || '';
        const cpuCores = parseInt(cpuResult.output?.trim() || '1', 10);
        let memory = { total: 0, used: 0, free: 0, usagePercent: 0 };
        const memLines = memOutput.split('\n');
        const memLine = memLines.find(l => l.includes('Mem:'));
        if (memLine) {
            const parts = memLine.trim().split(/\s+/);
            if (parts.length >= 4) {
                const total = this.parseMemSize(parts[1]);
                const used = this.parseMemSize(parts[2]);
                const free = this.parseMemSize(parts[3]);
                memory = { total, used, free, usagePercent: total > 0 ? (used / total) * 100 : 0 };
            }
        }
        let disk = { total: 0, used: 0, free: 0, usagePercent: 0 };
        const diskLines = diskOutput.split('\n').filter(l => l.trim());
        if (diskLines.length > 1) {
            const rootLine = diskLines.find(l => l.includes('/dev/')) || diskLines[1];
            const parts = rootLine.trim().split(/\s+/);
            if (parts.length >= 6) {
                const total = this.parseMemSize(parts[1]);
                const used = this.parseMemSize(parts[2]);
                const free = this.parseMemSize(parts[3]);
                const usagePercent = parseInt(parts[4].replace('%', ''), 10);
                disk = { total, used, free, usagePercent };
            }
        }
        const loadMatch = loadOutput.match(/load average:\s+([\d.]+),\s+([\d.]+),\s+([\d.]+)/);
        const load = loadMatch ? [parseFloat(loadMatch[1]), parseFloat(loadMatch[2]), parseFloat(loadMatch[3])] : [0, 0, 0];
        let uptime = 0;
        const uptimeMatch = loadOutput.match(/up\s+(\d+)\s+days?/);
        const hoursMatch = loadOutput.match(/up\s+(?:\d+\s+days?,\s+)?(\d+):(\d+)/);
        if (uptimeMatch)
            uptime += parseInt(uptimeMatch[1], 10) * 86400;
        if (hoursMatch)
            uptime += parseInt(hoursMatch[1], 10) * 3600 + parseInt(hoursMatch[2], 10) * 60;
        return {
            hostname: 'changji-server',
            platform: 'linux',
            uptime,
            cpu: { usage: (load[0] / cpuCores) * 100, cores: cpuCores, model: 'Intel Xeon' },
            memory,
            disk,
            load,
            timestamp: Date.now(),
        };
    }
    async getServices() {
        const result = await this.agentExecute('systemctl list-units --type=service --state=running --no-pager --no-legend | head -20');
        const output = result.output || '';
        const lines = output.split('\n').filter(l => l.trim());
        const services = lines.map(line => {
            const parts = line.trim().split(/\s+/);
            return {
                name: parts[0]?.replace('.service', '') || 'unknown',
                status: parts[3] || 'unknown',
                active: (parts[3] || '').includes('running') || (parts[3] || '').includes('active'),
            };
        }).filter(s => s.name !== 'unknown');
        return services;
    }
    async getLogs(service, lines = 100) {
        let command = '';
        if (service === 'nginx') {
            command = `tail -n ${lines} /var/log/nginx/access.log 2>/dev/null || tail -n ${lines} /var/log/nginx/error.log 2>/dev/null || echo 'Nginx日志文件未找到'`;
        }
        else if (service === 'api') {
            command = `pm2 logs changji-api --lines ${lines} --nostream 2>/dev/null || echo 'API日志获取失败'`;
        }
        else if (service === 'postgresql') {
            command = `tail -n ${lines} /var/log/postgresql/postgresql-*.log 2>/dev/null || journalctl -u postgresql --no-pager -n ${lines} 2>/dev/null || echo 'PostgreSQL日志获取失败'`;
        }
        else if (service === 'redis') {
            command = `tail -n ${lines} /var/log/redis/redis-server.log 2>/dev/null || journalctl -u redis-server --no-pager -n ${lines} 2>/dev/null || echo 'Redis日志获取失败'`;
        }
        else {
            command = `journalctl -u ${service} --no-pager -n ${lines} 2>/dev/null || echo '服务日志获取失败'`;
        }
        const result = await this.agentExecute(command, 30);
        return { logs: result.output || '暂无日志数据' };
    }
    validateCommand(command) {
        for (const pattern of this.forbiddenPatterns) {
            if (command.includes(pattern)) {
                return { valid: false, reason: `命令包含危险操作: ${pattern}` };
            }
        }
        const cmd = command.trim().split(' ')[0];
        const isAllowed = this.allowedCommands.some(allowed => command.startsWith(allowed) || cmd === allowed);
        if (!isAllowed) {
            return { valid: false, reason: `命令不在白名单中: ${cmd}` };
        }
        return { valid: true };
    }
    async executeCommand(command, timeout = 30) {
        const validation = this.validateCommand(command);
        if (!validation.valid) {
            throw new common_1.HttpException(validation.reason, 403);
        }
        const result = await this.agentExecute(command, timeout);
        return { output: result.output || '命令执行完成，无输出' };
    }
    parseMemSize(value) {
        if (!value)
            return 0;
        const match = value.match(/([\d.]+)([A-Za-z]*)/);
        if (!match)
            return 0;
        const num = parseFloat(match[1]);
        const unit = match[2].toUpperCase();
        const units = {
            '': 1, 'B': 1, 'K': 1024, 'KB': 1024, 'M': 1024 * 1024, 'MB': 1024 * 1024, 'MI': 1024 * 1024,
            'G': 1024 * 1024 * 1024, 'GB': 1024 * 1024 * 1024, 'GI': 1024 * 1024 * 1024,
            'T': 1024 * 1024 * 1024 * 1024, 'TB': 1024 * 1024 * 1024 * 1024,
        };
        return Math.floor(num * (units[unit] || 1));
    }
};
exports.MonitorService = MonitorService;
exports.MonitorService = MonitorService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [axios_1.HttpService])
], MonitorService);
//# sourceMappingURL=monitor.service.js.map