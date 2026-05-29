import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { PlanService } from '../plan/plan.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly planService: PlanService,
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

  // 手动调整用户配额
  @Post('users/:id/adjust-quota')
  async adjustUserQuota(
    @Param('id') userId: string,
    @Body() data: { amount: number; reason?: string },
  ) {
    const result = await this.adminService.adjustUserQuota(userId, data.amount, data.reason);
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

  // 套餐场景默认模型配置
  @Get('plans/:id/default-configs')
  async getPlanDefaultConfigs(@Param('id') planId: string) {
    const data = await this.adminService.getPlanDefaultConfigs(planId);
    return { code: 200, message: 'success', data };
  }

  @Post('plans/:id/default-configs')
  async setPlanDefaultConfig(
    @Param('id') planId: string,
    @Body() data: { functionType: string; modelPattern: string; isActive?: boolean },
  ) {
    const result = await this.adminService.setPlanDefaultConfig(planId, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('plans/default-configs/:configId')
  async deletePlanDefaultConfig(@Param('configId') configId: string) {
    await this.adminService.deletePlanDefaultConfig(configId);
    return { code: 200, message: 'success', data: null };
  }

  // 多模式计费：套餐功能配额管理
  @Get('plans/:id/feature-quotas')
  async getPlanFeatureQuotas(@Param('id') planId: string) {
    const data = await this.planService.getPlanFeatureQuotas(planId);
    return { code: 200, message: 'success', data };
  }

  @Post('plans/:id/feature-quotas')
  async setPlanFeatureQuota(
    @Param('id') planId: string,
    @Body() data: { featureType: string; quotaValue: number; quotaUnit: string; multiplier?: number },
  ) {
    const result = await this.planService.setPlanFeatureQuota(planId, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('plans/feature-quotas/:quotaId')
  async deletePlanFeatureQuota(@Param('quotaId') quotaId: string) {
    await this.planService.deletePlanFeatureQuota(quotaId);
    return { code: 200, message: 'success', data: null };
  }

  // 多模式计费：Token价格管理
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

  // 计费标准管理
  @Get('billing-standards')
  async getBillingStandards() {
    const data = await this.adminService.getBillingStandards();
    return { code: 200, message: 'success', data };
  }

  @Post('billing-standards')
  async createBillingStandard(@Body() data: any) {
    const result = await this.adminService.createBillingStandard(data);
    return { code: 200, message: 'success', data: result };
  }

  @Put('billing-standards/:id')
  async updateBillingStandard(@Param('id') id: string, @Body() data: any) {
    const result = await this.adminService.updateBillingStandard(id, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('billing-standards/:id')
  async deleteBillingStandard(@Param('id') id: string) {
    await this.adminService.deleteBillingStandard(id);
    return { code: 200, message: 'success', data: null };
  }

  // API系数配置管理
  @Get('api-policies')
  async getApiPolicies(@Query('planId') planId?: string) {
    const data = await this.adminService.getApiPolicies(planId);
    return { code: 200, message: 'success', data };
  }

  @Post('api-policies')
  async createApiPolicy(@Body() data: any) {
    const result = await this.adminService.createApiPolicy(data);
    return { code: 200, message: 'success', data: result };
  }

  @Put('api-policies/:id')
  async updateApiPolicy(@Param('id') id: string, @Body() data: any) {
    const result = await this.adminService.updateApiPolicy(id, data);
    return { code: 200, message: 'success', data: result };
  }

  @Delete('api-policies/:id')
  async deleteApiPolicy(@Param('id') id: string) {
    await this.adminService.deleteApiPolicy(id);
    return { code: 200, message: 'success', data: null };
  }

  // 多模式计费：用户功能使用查询
  @Get('users/:id/feature-usage')
  async getUserFeatureUsage(@Param('id') userId: string) {
    const data = await this.adminService.getUserFeatureUsage(userId);
    return { code: 200, message: 'success', data };
  }
}
