import { Injectable, HttpException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class MonitorService {
  private readonly agentUrl = 'http://127.0.0.1:8848';
  private readonly agentToken = 'changji-agent-2026';

  constructor(private readonly httpService: HttpService) {}

  private async agentRequest(endpoint: string, method: 'get' | 'post' = 'get', data?: any) {
    try {
      const response = method === 'get'
        ? await firstValueFrom(
            this.httpService.get(`${this.agentUrl}${endpoint}`, {
              headers: { 'X-Agent-Token': this.agentToken },
            }),
          )
        : await firstValueFrom(
            this.httpService.post(`${this.agentUrl}${endpoint}`, data, {
              headers: { 'X-Agent-Token': this.agentToken },
            }),
          );
      return response.data;
    } catch (error) {
      throw new HttpException(
        error.response?.data || 'Agent request failed',
        error.response?.status || 500,
      );
    }
  }

  async getSystemInfo() {
    const data = await this.agentRequest('/info');
    
    // 解析内存信息
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
    
    // 解析磁盘信息
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
    
    // 解析负载信息
    const loadMatch = data.load?.match(/load average:\s+(\d+\.?\d*),\s+(\d+\.?\d*),\s+(\d+\.?\d*)/);
    const load = loadMatch ? [
      parseFloat(loadMatch[1]),
      parseFloat(loadMatch[2]),
      parseFloat(loadMatch[3]),
    ] : [0, 0, 0];
    
    // 解析运行时间
    let uptime = 0;
    const uptimeMatch = data.load?.match(/up\s+(\d+)\s+days?/);
    const hoursMatch = data.load?.match(/up\s+(?:\d+\s+days?,\s+)?(\d+):(\d+)/);
    if (uptimeMatch) {
      uptime += parseInt(uptimeMatch[1], 10) * 86400;
    }
    if (hoursMatch) {
      uptime += parseInt(hoursMatch[1], 10) * 3600 + parseInt(hoursMatch[2], 10) * 60;
    }
    
    // 解析 CPU 信息
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
    
    return Object.entries(services).map(([name, info]: [string, any]) => ({
      name,
      status: info.status,
      active: info.status === 'active',
    }));
  }

  async getLogs(service: string, lines = 100) {
    return this.agentRequest('/logs', 'post', { service, lines });
  }

  async executeCommand(command: string, timeout = 30) {
    return this.agentRequest('/execute', 'post', { command, timeout });
  }
  
  private parseSize(value: string, unit: string): number {
    const num = parseFloat(value);
    const units = { 'B': 1, 'KB': 1024, 'MB': 1024*1024, 'GB': 1024*1024*1024, 'TB': 1024*1024*1024*1024 };
    const multiplier = units[unit.toUpperCase()] || 1;
    return Math.floor(num * multiplier);
  }
}
