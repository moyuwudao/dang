import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Optional, HttpException, HttpStatus } from '@nestjs/common';
import { AdminService } from './admin.service';
import { PlanService } from '../plan/plan.service';
import { ApiKeyService } from '../api-key/api-key.service';
import { MonitorService } from '../monitor/monitor.service';
import { MetricsService } from '../monitor/metrics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { CreateApiKeyDto } from '../api-key/dto';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly planService: PlanService,
    private readonly apiKeyService: ApiKeyService,
    @Optional() private readonly monitorService?: MonitorService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  @Get('stats')
  async getStats() {
    const data = await this.adminService.getStats();
    return { code: 200, message: 'success', data };
  }

  @Get('users')
  async getUsers(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
  ) {
    const data = await this.adminService.getUsers(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      search,
    );
    return { code: 200, message: 'success', data };
  }

  @Post('users')
  async createUser(@Body() data: any) {
    const result = await this.adminService.createUser(data);
    return { code: 200, message: '创建成功', data: result };
  }

  @Get('users/:id')
  async getUserById(@Param('id') id: string) {
    const result = await this.adminService.getUserById(id);
    return { code: 200, message: 'success', data: result };
  }

  @Put('users/:id')
  async updateUser(@Param('id') id: string, @Body() data: any) {
    const result = await this.adminService.updateUser(id, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: string) {
    await this.adminService.deleteUser(id);
    return { code: 200, message: 'success', data: null };
  }

  @Get('plans')
  async getPlans() {
    const data = await this.adminService.getPlans();
    return { code: 200, message: 'success', data };
  }

  @Get('plans/:id')
  async getPlanById(@Param('id') id: string) {
    const data = await this.planService.getPlanById(id);
    return { code: 200, message: 'success', data };
  }

  @Post('plans')
  async createPlan(@Body() data: any) {
    const result = await this.adminService.createPlan(data);
    return { code: 200, message: 'success', data: result };
  }

  @Put('plans/:id')
  async updatePlan(@Param('id') id: string, @Body() data: any) {
    const result = await this.adminService.updatePlan(id, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('plans/:id')
  async deletePlan(@Param('id') id: string) {
    await this.adminService.deletePlan(id);
    return { code: 200, message: 'success', data: null };
  }

  @Get('subscriptions')
  async getSubscriptions(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: string,
  ) {
    const data = await this.adminService.getSubscriptions(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      status,
    );
    return { code: 200, message: 'success', data };
  }

  @Put('subscriptions/:id')
  async updateSubscription(@Param('id') id: string, @Body() data: any) {
    const result = await this.adminService.updateSubscription(id, data);
    return { code: 200, message: 'success', data: result };
  }

  @Post('users/:id/subscribe')
  async assignPlanToUser(@Param('id') userId: string, @Body() data: { planId: string }) {
    const result = await this.adminService.assignPlanToUser(userId, data.planId);
    return { code: 200, message: 'success', data: result };
  }

  @Get('recharge-records')
  async getRechargeRecords(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const data = await this.adminService.getRechargeRecords(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
    return { code: 200, message: 'success', data };
  }

  @Get('charts/user-growth')
  async getUserGrowth(@Query('days') days?: string) {
    const data = await this.adminService.getUserGrowth(days ? parseInt(days, 10) : 7);
    return { code: 200, message: 'success', data };
  }

  @Get('charts/revenue-trend')
  async getRevenueTrend(@Query('days') days?: string) {
    const data = await this.adminService.getRevenueTrend(days ? parseInt(days, 10) : 7);
    return { code: 200, message: 'success', data };
  }

  // API 调用日志
  @Get('api-usage-logs')
  async getApiUsageLogs(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('userId') userId?: string,
    @Query('provider') provider?: string,
  ) {
    const data = await this.adminService.getApiUsageLogs(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      userId,
      provider,
    );
    return { code: 200, message: 'success', data };
  }

  // 手动调整用户Token余额
  @Post('users/:id/adjust-tokens')
  async adjustUserTokens(
    @Param('id') userId: string,
    @Body() data: { amount: number; reason?: string },
  ) {
    const result = await this.adminService.adjustUserTokens(userId, data.amount, data.reason);
    return { code: 200, message: 'success', data: result };
  }

  // 收入统计
  @Get('revenue-stats')
  async getRevenueStats(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const data = await this.adminService.getRevenueStats(startDate, endDate);
    return { code: 200, message: 'success', data };
  }

  // Token单价管理
  @Get('token-pricing')
  async getTokenPricing() {
    const data = await this.adminService.getTokenPricing();
    return { code: 200, message: 'success', data };
  }

  @Post('token-pricing')
  async createTokenPricing(@Body() data: any) {
    const result = await this.adminService.createTokenPricing(data);
    return { code: 200, message: 'success', data: result };
  }

  @Put('token-pricing/:id')
  async updateTokenPricing(@Param('id') id: string, @Body() data: any) {
    const result = await this.adminService.updateTokenPricing(id, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('token-pricing/:id')
  async deleteTokenPricing(@Param('id') id: string) {
    await this.adminService.deleteTokenPricing(id);
    return { code: 200, message: 'success', data: null };
  }

  // API配置管理（含基础系数）
  @Get('api-configs')
  async getApiConfigs() {
    const data = await this.adminService.getApiConfigs();
    return { code: 200, message: 'success', data };
  }

  @Post('api-configs')
  async createApiConfig(@Body() data: any) {
    const result = await this.adminService.createApiConfig(data);
    return { code: 200, message: 'success', data: result };
  }

  @Put('api-configs/:id')
  async updateApiConfig(@Param('id') id: string, @Body() data: any) {
    const result = await this.adminService.updateApiConfig(id, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('api-configs/:id')
  async deleteApiConfig(@Param('id') id: string) {
    await this.adminService.deleteApiConfig(id);
    return { code: 200, message: 'success', data: null };
  }

  // API Key 管理
  @Get('api-keys')
  async getApiKeys() {
    const result = await this.apiKeyService.getApiKeys();
    return result;
  }

  @Get('api-keys/stats')
  async getApiKeyStats() {
    const result = await this.apiKeyService.getApiKeyStats();
    return result;
  }

  @Post('api-keys')
  async createApiKey(@Body() dto: CreateApiKeyDto) {
    const result = await this.apiKeyService.createApiKey(dto);
    return result;
  }

  @Post('api-keys/batch')
  async batchCreateApiKeys(@Body() body: { keys: CreateApiKeyDto[] }) {
    const results = [];
    for (const dto of body.keys) {
      try {
        const result = await this.apiKeyService.createApiKey(dto);
        results.push({ success: true, data: result.data });
      } catch (error) {
        results.push({ success: false, error: error.message, name: dto.name });
      }
    }
    return {
      code: 200,
      message: '批量创建完成',
      data: results,
    };
  }

  @Post('api-keys/:id/test')
  async testApiKey(@Param('id') id: string) {
    const result = await this.apiKeyService.testApiKey(id);
    return result;
  }

  @Put('api-keys/:id')
  async updateApiKey(@Param('id') id: string, @Body() dto: Partial<CreateApiKeyDto>) {
    const result = await this.apiKeyService.updateApiKey(id, dto);
    return result;
  }

  @Delete('api-keys/:id')
  async deleteApiKey(@Param('id') id: string) {
    const result = await this.apiKeyService.deleteApiKey(id);
    return result;
  }

  // 监控接口
  @Get('monitor/realtime')
  async getRealtimeMetrics() {
    if (!this.metricsService) {
      throw new HttpException('Metrics service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
    }
    const data = await this.metricsService.getRealtimeMetrics();
    return { code: 200, message: 'success', data };
  }

  @Get('monitor/trend')
  async getTrendData(@Query('days') days?: string) {
    if (!this.metricsService) {
      throw new HttpException('Metrics service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
    }
    const data = await this.metricsService.getTrendData(parseInt(days || '7', 10));
    return { code: 200, message: 'success', data };
  }

  @Get('monitor/system-info')
  async getSystemInfo() {
    if (!this.monitorService) {
      throw new HttpException('Monitor service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
    }
    const data = await this.monitorService.getSystemInfo();
    return { code: 200, message: 'success', data };
  }

  @Get('monitor/services')
  async getServices() {
    if (!this.monitorService) {
      throw new HttpException('Monitor service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
    }
    const data = await this.monitorService.getServices();
    return { code: 200, message: 'success', data };
  }

  @Get('monitor/logs')
  async getMonitorLogs(@Query('service') service: string, @Query('lines') lines?: string) {
    if (!this.monitorService) {
      throw new HttpException('Monitor service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
    }
    const data = await this.monitorService.getLogs(service, parseInt(lines || '100', 10));
    return { code: 200, message: 'success', data };
  }

  @Post('monitor/execute')
  async executeCommand(@Body() body: { command: string; timeout?: number }) {
    if (!this.monitorService) {
      throw new HttpException('Monitor service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
    }
    const data = await this.monitorService.executeCommand(body.command, body.timeout || 30);
    return { code: 200, message: 'success', data };
  }
}
