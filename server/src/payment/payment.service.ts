import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { SubscriptionService } from '../subscription/subscription.service';
import { WechatPayService } from './wechat-pay.service';
import { AlipayService } from './alipay.service';

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);

  constructor(
    @InjectRepository(RechargeRecord)
    private rechargeRecordRepository: Repository<RechargeRecord>,
    private readonly subscriptionService: SubscriptionService,
    private readonly wechatPayService: WechatPayService,
    private readonly alipayService: AlipayService,
  ) {}

  // 创建充值订单
  async createRechargeOrder(
    userId: string,
    params: {
      amount: number;
      paymentMethod: string;
      description?: string;
    },
  ) {
    const { amount, paymentMethod } = params;

    // 生成订单号
    const orderId = `RE${Date.now()}${Math.random().toString(36).substr(2, 6)}`;

    // 创建充值记录
    const record = this.rechargeRecordRepository.create({
      userId,
      amountCents: amount,
      paymentMethod,
      status: 'pending',
      remark: params.description || `充值 ${amount / 100} 元`,
    });
    await this.rechargeRecordRepository.save(record);

    // 调用支付接口创建预支付订单
    let paymentData: any;
    try {
      if (paymentMethod === 'wechat') {
        paymentData = await this.wechatPayService.createOrder({
          orderId,
          amount,
          description: record.remark || '',
        });
      } else if (paymentMethod === 'alipay') {
        paymentData = await this.alipayService.createOrder({
          orderId,
          amount,
          description: record.remark || '',
        });
      } else {
        throw new Error('不支持的支付方式');
      }
    } catch (error) {
      // 更新订单状态为失败
      record.status = 'failed';
      await this.rechargeRecordRepository.save(record);
      throw error;
    }

    return {
      code: 200,
      message: '订单创建成功',
      data: {
        orderId,
        amount,
        paymentMethod,
        paymentData,
      },
    };
  }

  // 查询订单状态
  async getOrderStatus(orderId: string) {
    const record = await this.rechargeRecordRepository.findOne({
      where: { id: orderId },
    });

    if (!record) {
      return {
        code: 404,
        message: '订单不存在',
        data: null,
      };
    }

    return {
      code: 200,
      message: 'success',
      data: {
        orderId: record.id,
        status: record.status,
        amount: record.amountCents,
        paymentMethod: record.paymentMethod,
        createdAt: record.createdAt,
      },
    };
  }

  // 处理微信支付回调
  async handleWechatCallback(body: any) {
    try {
      const result = await this.wechatPayService.verifyCallback(body);
      
      if (result.success) {
        await this.handlePaymentSuccess(result.orderId, result.amount);
      }

      return { code: 'SUCCESS', message: '成功' };
    } catch (error) {
      this.logger.error('微信支付回调处理失败:', error);
      return { code: 'FAIL', message: error.message };
    }
  }

  // 处理支付宝回调
  async handleAlipayCallback(body: any) {
    try {
      const result = await this.alipayService.verifyCallback(body);
      
      if (result.success) {
        await this.handlePaymentSuccess(result.orderId, result.amount);
      }

      return { code: 'SUCCESS', message: '成功' };
    } catch (error) {
      this.logger.error('支付宝回调处理失败:', error);
      return { code: 'FAIL', message: error.message };
    }
  }

  // 处理支付成功
  private async handlePaymentSuccess(orderId: string, amount: number) {
    const record = await this.rechargeRecordRepository.findOne({
      where: { id: orderId },
    });

    if (!record || record.status === 'completed') {
      return;
    }

    // 更新订单状态
    record.status = 'completed';
    await this.rechargeRecordRepository.save(record);

    // 增加用户余额
    await this.subscriptionService.recharge(record.userId, {
      amountCents: record.amountCents,
      paymentMethod: record.paymentMethod,
    });

    this.logger.log(`用户 ${record.userId} 充值成功: ${record.amountCents} 分`);
  }

  // 获取充值记录
  async getRechargeRecords(userId: string, page: number, limit: number) {
    const [records, total] = await this.rechargeRecordRepository.findAndCount({
      where: { userId },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      code: 200,
      message: 'success',
      data: {
        records,
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
