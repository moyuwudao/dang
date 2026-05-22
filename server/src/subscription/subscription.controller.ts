import { Controller, Get, Post, UseGuards, Req, Body, Query } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateSubscriptionDto, CreatePlanDto, RechargeDto, RefundDto } from './dto';

@Controller('subscription')
export class SubscriptionController {
  constructor(private readonly subscriptionService: SubscriptionService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async getSubscription(@Req() req) {
    const data = await this.subscriptionService.getSubscription(req.user.sub);
    return { code: 200, message: 'success', data };
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  async createSubscription(@Req() req, @Body() dto: CreateSubscriptionDto) {
    const data = await this.subscriptionService.createSubscription(req.user.sub, dto.planId);
    return { code: 200, message: 'success', data };
  }

  @Get('plans')
  async getPlans(@Query('type') type?: string) {
    const data = await this.subscriptionService.getPlans(type);
    return { code: 200, message: 'success', data };
  }

  @Post('plans')
  @UseGuards(JwtAuthGuard)
  async createPlan(@Body() dto: CreatePlanDto) {
    const data = await this.subscriptionService.createPlan(dto);
    return { code: 200, message: 'success', data };
  }

  @Post('quota/use')
  @UseGuards(JwtAuthGuard)
  async useQuota(@Req() req, @Body() body: { amount: number }) {
    const data = await this.subscriptionService.useQuota(req.user.sub, body.amount);
    return { code: 200, message: 'success', data };
  }

  @Get('balance')
  @UseGuards(JwtAuthGuard)
  async getBalance(@Req() req) {
    const data = await this.subscriptionService.getBalance(req.user.sub);
    return { code: 200, message: 'success', data };
  }

  @Post('recharge')
  @UseGuards(JwtAuthGuard)
  async recharge(@Req() req, @Body() dto: RechargeDto) {
    const data = await this.subscriptionService.recharge(req.user.sub, dto);
    return { code: 200, message: 'success', data };
  }

  @Post('refund')
  @UseGuards(JwtAuthGuard)
  async refund(@Req() req, @Body() dto: RefundDto) {
    const data = await this.subscriptionService.refund(req.user.sub, dto);
    return { code: 200, message: 'success', data };
  }

  @Get('records')
  @UseGuards(JwtAuthGuard)
  async getRechargeRecords(@Req() req) {
    const data = await this.subscriptionService.getRechargeRecords(req.user.sub);
    return { code: 200, message: 'success', data };
  }
}
