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
    }
    async agentRequest(endpoint, method = 'get', data) {
        try {
            const response = method === 'get'
                ? await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.agentUrl}${endpoint}`, {
                    headers: { 'X-Agent-Token': this.agentToken },
                }))
                : await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.agentUrl}${endpoint}`, data, {
                    headers: { 'X-Agent-Token': this.agentToken },
                }));
            return response.data;
        }
        catch (error) {
            throw new common_1.HttpException(error.response?.data || 'Agent request failed', error.response?.status || 500);
        }
    }
    async getSystemInfo() {
        const data = await this.agentRequest('/info');
        const memoryMatch = data.memory?.match(/Mem:\s+(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)/);
        let memory = {
            total: 0,
            used: 0,
            free: 0,
            usagePercent: 0,
        };
        if (memoryMatch) {
            const total = this.parseSize(memoryMatch[1], memoryMatch[2]);
            const used = this.parseSize(memoryMatch[3], memoryMatch[4]);
            memory = {
                total,
                used,
                free: this.parseSize(memoryMatch[5], memoryMatch[6]),
                usagePercent: total > 0 ? (used / total) * 100 : 0,
            };
        }
        let disk = {
            total: 0,
            used: 0,
            free: 0,
            usagePercent: 0,
        };
        const diskLines = data.disk?.split('\n').filter(line => line.trim());
        if (diskLines?.length > 1) {
            const rootLine = diskLines.find(line => line.includes('/dev/vda3')) || diskLines[1];
            const diskMatch = rootLine?.match(/(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)\s+(\d+)%/);
            if (diskMatch) {
                disk = {
                    total: this.parseSize(diskMatch[1], diskMatch[2]),
                    used: this.parseSize(diskMatch[3], diskMatch[4]),
                    free: this.parseSize(diskMatch[5], diskMatch[6]),
                    usagePercent: parseInt(diskMatch[7], 10),
                };
            }
        }
        const loadMatch = data.load?.match(/load average:\s+(\d+\.?\d*),\s+(\d+\.?\d*),\s+(\d+\.?\d*)/);
        const load = loadMatch ? [
            parseFloat(loadMatch[1]),
            parseFloat(loadMatch[2]),
            parseFloat(loadMatch[3]),
        ] : [0, 0, 0];
        let uptime = 0;
        const uptimeMatch = data.load?.match(/up\s+(\d+)\s+days?/);
        const hoursMatch = data.load?.match(/up\s+(?:\d+\s+days?,\s+)?(\d+):(\d+)/);
        if (uptimeMatch) {
            uptime += parseInt(uptimeMatch[1], 10) * 86400;
        }
        if (hoursMatch) {
            uptime += parseInt(hoursMatch[1], 10) * 3600 + parseInt(hoursMatch[2], 10) * 60;
        }
        const cpu = {
            usage: (load[0] / parseInt(data.cpu_cores || '1', 10)) * 100,
            cores: parseInt(data.cpu_cores || '1', 10),
            model: 'Intel Xeon',
        };
        return {
            hostname: 'changji-server',
            platform: 'linux',
            uptime,
            cpu,
            memory,
            disk,
            load,
            timestamp: data.timestamp,
        };
    }
    async getServices() {
        const data = await this.agentRequest('/services');
        const services = data.services || {};
        return Object.entries(services).map(([name, info]) => ({
            name,
            status: info.status,
            active: info.status === 'active',
        }));
    }
    async getLogs(service, lines = 100) {
        return this.agentRequest('/logs', 'post', { service, lines });
    }
    async executeCommand(command, timeout = 30) {
        return this.agentRequest('/execute', 'post', { command, timeout });
    }
    parseSize(value, unit) {
        const num = parseFloat(value);
        const units = {
            'B': 1, 'K': 1024, 'KB': 1024, 'M': 1024 * 1024, 'MB': 1024 * 1024, 'MI': 1024 * 1024, 'MIB': 1024 * 1024,
            'G': 1024 * 1024 * 1024, 'GB': 1024 * 1024 * 1024, 'GI': 1024 * 1024 * 1024, 'GIB': 1024 * 1024 * 1024,
            'T': 1024 * 1024 * 1024 * 1024, 'TB': 1024 * 1024 * 1024 * 1024
        };
        const multiplier = units[unit.toUpperCase()] || 1;
        return Math.floor(num * multiplier);
    }
};
exports.MonitorService = MonitorService;
exports.MonitorService = MonitorService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [axios_1.HttpService])
], MonitorService);
//# sourceMappingURL=monitor.service.js.map