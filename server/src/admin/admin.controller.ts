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
    return this.adminService.getStats();
  }

  @Get('users')
  async getUsers(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
  ) {
    return this.adminService.getUsers(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      search,
    );
  }

  @Put('users/:id')
  async updateUser(@Param('id') id: string, @Body() data: any) {
    return this.adminService.updateUser(id, data);
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: string) {
    return this.adminService.deleteUser(id);
  }

  @Get('plans')
  async getPlans() {
    return this.adminService.getPlans();
  }

  @Post('plans')
  async createPlan(@Body() data: any) {
    return this.adminService.createPlan(data);
  }

  @Put('plans/:id')
  async updatePlan(@Param('id') id: string, @Body() data: any) {
    return this.adminService.updatePlan(id, data);
  }

  @Delete('plans/:id')
  async deletePlan(@Param('id') id: string) {
    return this.adminService.deletePlan(id);
  }

  @Get('subscriptions')
  async getSubscriptions(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: string,
  ) {
    return this.adminService.getSubscriptions(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      status,
    );
  }

  @Put('subscriptions/:id')
  async updateSubscription(@Param('id') id: string, @Body() data: any) {
    return this.adminService.updateSubscription(id, data);
  }

  @Get('recharge-records')
  async getRechargeRecords(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getRechargeRecords(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Get('charts/user-growth')
  async getUserGrowth(@Query('days') days?: string) {
    return this.adminService.getUserGrowth(days ? parseInt(days, 10) : 7);
  }

  @Get('charts/revenue-trend')
  async getRevenueTrend(@Query('days') days?: string) {
    return this.adminService.getRevenueTrend(days ? parseInt(days, 10) : 7);
  }
}
