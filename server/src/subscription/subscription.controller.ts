import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('subscription')
export class SubscriptionController {
  constructor(private readonly subscriptionService: SubscriptionService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async getSubscription(@Req() req) {
    return this.subscriptionService.getSubscription(req.user.sub);
  }

  @Get('plans')
  async getPlans() {
    return this.subscriptionService.getPlans();
  }
}
