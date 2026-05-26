import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { SubscriptionService } from './subscription.service';

@Injectable()
export class SubscriptionSchedulerService {
  private readonly logger = new Logger(SubscriptionSchedulerService.name);

  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    private readonly subscriptionService: SubscriptionService,
  ) {}

  // 每天检查一次即将过期的订阅
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async checkExpiringSubscriptions() {
    this.logger.log('开始检查即将过期的订阅');

    const now = new Date();
    const threeDaysLater = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    const oneDayLater = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);

    // 获取3天内过期的订阅
    const expiringSoon = await this.subscriptionRepository.find({
      where: {
        status: 'active',
        expiresAt: LessThan(threeDaysLater),
      },
    });

    for (const subscription of expiringSoon) {
      const daysUntilExpiry = Math.ceil(
        (subscription.expiresAt.getTime() - now.getTime()) / (24 * 60 * 60 * 1000)
      );

      if (daysUntilExpiry <= 1) {
        this.logger.log(`订阅 ${subscription.id} 将在1天内过期，发送提醒`);
        // TODO: 发送过期提醒通知
      } else if (daysUntilExpiry <= 3) {
        this.logger.log(`订阅 ${subscription.id} 将在3天内过期，发送提醒`);
        // TODO: 发送过期提醒通知
      }
    }

    this.logger.log('过期订阅检查完成');
  }

  // 每小时检查一次已过期的订阅
  @Cron(CronExpression.EVERY_HOUR)
  async handleExpiredSubscriptions() {
    this.logger.log('开始处理已过期订阅');

    const now = new Date();

    // 获取已过期但仍标记为 active 的订阅
    const expiredSubscriptions = await this.subscriptionRepository.find({
      where: {
        status: 'active',
        expiresAt: LessThan(now),
      },
    });

    for (const subscription of expiredSubscriptions) {
      this.logger.log(`订阅 ${subscription.id} 已过期，更新状态`);
      
      // 更新订阅状态为过期
      subscription.status = 'expired';
      await this.subscriptionRepository.save(subscription);

      // TODO: 发送过期通知
      // TODO: 尝试自动续费（如果用户开启了自动续费）
    }

    this.logger.log('已过期订阅处理完成');
  }

  // 每天检查一次需要自动续费的订阅
  @Cron(CronExpression.EVERY_DAY_AT_1AM)
  async processAutoRenewal() {
    this.logger.log('开始处理自动续费');

    const now = new Date();
    const oneDayLater = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);

    // 获取明天过期且开启了自动续费的订阅
    // TODO: 添加 autoRenewal 字段到 Subscription 实体
    const renewals = await this.subscriptionRepository.find({
      where: {
        status: 'active',
        expiresAt: LessThan(oneDayLater),
      },
    });

    for (const subscription of renewals) {
      this.logger.log(`尝试自动续费订阅 ${subscription.id}`);
      
      try {
        // TODO: 检查用户余额是否足够
        // TODO: 扣除余额并延长订阅
        // TODO: 发送续费成功通知
      } catch (error) {
        this.logger.error(`自动续费失败: ${error.message}`);
        // TODO: 发送续费失败通知
      }
    }

    this.logger.log('自动续费处理完成');
  }
}
