import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { MonitorService } from './monitor.service';
import { MetricsService } from './metrics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('monitor')
@UseGuards(JwtAuthGuard, AdminGuard)
export class MonitorController {
  constructor(
    private readonly monitorService: MonitorService,
    private readonly metricsService: MetricsService,
  ) {}

  @Get('system')
  async getSystemInfo() {
    const data = await this.monitorService.getSystemInfo();
    return { code: 200, message: 'success', data };
  }

  @Get('services')
  async getServices() {
    const data = await this.monitorService.getServices();
    return { code: 200, message: 'success', data };
  }

  @Post('logs')
  async getLogs(@Body() body: { service: string; lines?: number }) {
    const data = await this.monitorService.getLogs(body.service, body.lines || 100);
    return { code: 200, message: 'success', data };
  }

  @Post('execute')
  async executeCommand(@Body() body: { command: string; timeout?: number }) {
    const data = await this.monitorService.executeCommand(body.command, body.timeout || 30);
    return { code: 200, message: 'success', data };
  }

  // API 监控指标
  @Get('metrics/realtime')
  async getRealtimeMetrics() {
    const data = await this.metricsService.getRealtimeMetrics();
    return { code: 200, message: 'success', data };
  }

  @Get('metrics/daily')
  async getDailyMetrics(@Query('date') date?: string) {
    const targetDate = date ? new Date(date) : new Date();
    const data = await this.metricsService.getDailyMetrics(targetDate);
    return { code: 200, message: 'success', data };
  }

  @Get('metrics/trend')
  async getTrendData(@Query('days') days?: string) {
    const data = await this.metricsService.getTrendData(parseInt(days || '7', 10));
    return { code: 200, message: 'success', data };
  }
}
