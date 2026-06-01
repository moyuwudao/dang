import { Controller, Get, Post, Delete, UseGuards, Req, Body, Query, Param } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateSubscriptionDto, CreatePlanDto, RechargeDto } from './dto';

@Controller('subscription')
export class SubscriptionController {
  constructor(private readonly subscriptionService: SubscriptionService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async getSubscription(@Req() req) {
    return this.subscriptionService.getSubscription(req.user.sub);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  async createSubscription(@Req() req, @Body() dto: CreateSubscriptionDto) {
    return this.subscriptionService.createSubscription(req.user.sub, dto.planId);
  }

  @Get('plans')
  async getPlans(@Query('type') type?: string) {
    return this.subscriptionService.getPlans(type);
  }

  @Post('plans')
  @UseGuards(JwtAuthGuard)
  async createPlan(@Body() dto: CreatePlanDto) {
    return this.subscriptionService.createPlan(dto);
  }

  @Get('balance')
  @UseGuards(JwtAuthGuard)
  async getBalance(@Req() req) {
    return this.subscriptionService.getBalance(req.user.sub);
  }

  @Post('recharge')
  @UseGuards(JwtAuthGuard)
  async recharge(@Req() req, @Body() dto: RechargeDto) {
    return this.subscriptionService.rechargeTokens(req.user.sub, dto);
  }

  @Get('records')
  @UseGuards(JwtAuthGuard)
  async getRechargeRecords(@Req() req) {
    return this.subscriptionService.getRechargeRecords(req.user.sub);
  }
}
