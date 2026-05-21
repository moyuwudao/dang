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
    return this.agentRequest('/info');
  }

  async getServices() {
    return this.agentRequest('/services');
  }

  async getLogs(service: string, lines = 100) {
    return this.agentRequest('/logs', 'post', { service, lines });
  }

  async executeCommand(command: string, timeout = 30) {
    return this.agentRequest('/execute', 'post', { command, timeout });
  }
}
