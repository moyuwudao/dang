import { Controller, Post, Get, Body, Query, Param, Req, UseGuards } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  // 创建充值订单
  @Post('recharge')
  @UseGuards(JwtAuthGuard)
  async createRechargeOrder(
    @Req() req,
    @Body() body: {
      amount: number;        // 充值金额（分）
      paymentMethod: string;  // wechat | alipay
      description?: string;
    },
  ) {
    return this.paymentService.createRechargeOrder(req.user.sub, body);
  }

  // 查询订单状态
  @Get('order/:orderId')
  @UseGuards(JwtAuthGuard)
  async getOrderStatus(@Param('orderId') orderId: string) {
    return this.paymentService.getOrderStatus(orderId);
  }

  // 微信支付回调
  @Post('wechat/callback')
  async wechatCallback(@Body() body: any) {
    return this.paymentService.handleWechatCallback(body);
  }

  // 支付宝回调
  @Post('alipay/callback')
  async alipayCallback(@Body() body: any) {
    return this.paymentService.handleAlipayCallback(body);
  }

  // 获取充值记录
  @Get('records')
  @UseGuards(JwtAuthGuard)
  async getRechargeRecords(
    @Req() req,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.paymentService.getRechargeRecords(
      req.user.sub,
      parseInt(page || '1', 10),
      parseInt(limit || '20', 10),
    );
  }
}
