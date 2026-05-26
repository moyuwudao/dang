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

  @Post('quota/use')
  @UseGuards(JwtAuthGuard)
  async useQuota(@Req() req, @Body() body: { amount: number }) {
    return this.subscriptionService.useQuota(req.user.sub, body.amount);
  }

  @Get('balance')
  @UseGuards(JwtAuthGuard)
  async getBalance(@Req() req) {
    return this.subscriptionService.getBalance(req.user.sub);
  }

  @Post('recharge')
  @UseGuards(JwtAuthGuard)
  async recharge(@Req() req, @Body() dto: RechargeDto) {
    return this.subscriptionService.recharge(req.user.sub, dto);
  }

  @Post('refund')
  @UseGuards(JwtAuthGuard)
  async refund(@Req() req, @Body() dto: RefundDto) {
    return this.subscriptionService.refund(req.user.sub, dto);
  }

  @Get('records')
  @UseGuards(JwtAuthGuard)
  async getRechargeRecords(@Req() req) {
    return this.subscriptionService.getRechargeRecords(req.user.sub);
  }

  // API策略管理（管理员接口）
  @Get('plans/:id/policies')
  @UseGuards(JwtAuthGuard)
  async getPlanApiPolicies(@Param('id') planId: string) {
    const policies = await this.subscriptionService.getPlanApiPolicies(planId);
    return { code: 200, message: 'success', data: policies };
  }

  @Post('plans/:id/policies')
  @UseGuards(JwtAuthGuard)
  async setPlanApiPolicy(
    @Param('id') planId: string,
    @Body() body: { provider: string; multiplier: number; modelPattern?: string },
  ) {
    const policy = await this.subscriptionService.setPlanApiPolicy(
      planId,
      body.provider,
      body.multiplier,
      body.modelPattern,
    );
    return { code: 200, message: 'success', data: policy };
  }

  // API使用检查
  @Post('check-api')
  @UseGuards(JwtAuthGuard)
  async checkApiPermission(
    @Req() req,
    @Body() body: { provider: string; model: string },
  ) {
    const result = await this.subscriptionService.canUseApi(req.user.sub, body.provider, body.model);
    return { code: 200, message: 'success', data: result };
  }

  // 使用配额（带API差异化）
  @Post('quota/consume')
  @UseGuards(JwtAuthGuard)
  async consumeQuotaWithApi(
    @Req() req,
    @Body() body: { provider: string; model: string; tokens?: { prompt: number; completion: number } },
  ) {
    const result = await this.subscriptionService.consumeQuotaWithApi(
      req.user.sub,
      body.provider,
      body.model,
      body.tokens,
    );
    return { code: 200, message: 'success', data: result };
  }
}
