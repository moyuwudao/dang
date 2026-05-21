import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { MonitorService } from './monitor.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('monitor')
@UseGuards(JwtAuthGuard, AdminGuard)
export class MonitorController {
  constructor(private readonly monitorService: MonitorService) {}

  @Get('system')
  async getSystemInfo() {
    return this.monitorService.getSystemInfo();
  }

  @Get('services')
  async getServices() {
    return this.monitorService.getServices();
  }

  @Post('logs')
  async getLogs(@Body() body: { service: string; lines?: number }) {
    return this.monitorService.getLogs(body.service, body.lines || 100);
  }

  @Post('execute')
  async executeCommand(@Body() body: { command: string; timeout?: number }) {
    return this.monitorService.executeCommand(body.command, body.timeout || 30);
  }
}
