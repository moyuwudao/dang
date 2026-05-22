import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

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
}
