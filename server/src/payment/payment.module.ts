import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { JwtModule } from '@nestjs/jwt';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { WechatPayService } from './wechat-pay.service';
import { AlipayService } from './alipay.service';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { SubscriptionModule } from '../subscription/subscription.module';

@Module({
  imports: [
    HttpModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
      signOptions: { expiresIn: '15m' },
    }),
    TypeOrmModule.forFeature([RechargeRecord]),
    SubscriptionModule,
  ],
  controllers: [PaymentController],
  providers: [PaymentService, WechatPayService, AlipayService],
  exports: [PaymentService],
})
export class PaymentModule {}
