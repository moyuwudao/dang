"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var SubscriptionSchedulerService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SubscriptionSchedulerService = void 0;
const common_1 = require("@nestjs/common");
const schedule_1 = require("@nestjs/schedule");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const subscription_entity_1 = require("./entities/subscription.entity");
const subscription_service_1 = require("./subscription.service");
let SubscriptionSchedulerService = SubscriptionSchedulerService_1 = class SubscriptionSchedulerService {
    constructor(subscriptionRepository, subscriptionService) {
        this.subscriptionRepository = subscriptionRepository;
        this.subscriptionService = subscriptionService;
        this.logger = new common_1.Logger(SubscriptionSchedulerService_1.name);
    }
    async checkExpiringSubscriptions() {
        this.logger.log('开始检查即将过期的订阅');
        const now = new Date();
        const threeDaysLater = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
        const oneDayLater = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);
        const expiringSoon = await this.subscriptionRepository.find({
            where: {
                status: 'active',
                expiresAt: (0, typeorm_2.LessThan)(threeDaysLater),
            },
        });
        for (const subscription of expiringSoon) {
            const daysUntilExpiry = Math.ceil((subscription.expiresAt.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));
            if (daysUntilExpiry <= 1) {
                this.logger.log(`订阅 ${subscription.id} 将在1天内过期，发送提醒`);
            }
            else if (daysUntilExpiry <= 3) {
                this.logger.log(`订阅 ${subscription.id} 将在3天内过期，发送提醒`);
            }
        }
        this.logger.log('过期订阅检查完成');
    }
    async handleExpiredSubscriptions() {
        this.logger.log('开始处理已过期订阅');
        const now = new Date();
        const expiredSubscriptions = await this.subscriptionRepository.find({
            where: {
                status: 'active',
                expiresAt: (0, typeorm_2.LessThan)(now),
            },
        });
        for (const subscription of expiredSubscriptions) {
            this.logger.log(`订阅 ${subscription.id} 已过期，更新状态`);
            subscription.status = 'expired';
            await this.subscriptionRepository.save(subscription);
        }
        this.logger.log('已过期订阅处理完成');
    }
    async processAutoRenewal() {
        this.logger.log('开始处理自动续费');
        const now = new Date();
        const oneDayLater = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);
        const renewals = await this.subscriptionRepository.find({
            where: {
                status: 'active',
                expiresAt: (0, typeorm_2.LessThan)(oneDayLater),
            },
        });
        for (const subscription of renewals) {
            this.logger.log(`尝试自动续费订阅 ${subscription.id}`);
            try {
            }
            catch (error) {
                this.logger.error(`自动续费失败: ${error.message}`);
            }
        }
        this.logger.log('自动续费处理完成');
    }
};
exports.SubscriptionSchedulerService = SubscriptionSchedulerService;
__decorate([
    (0, schedule_1.Cron)(schedule_1.CronExpression.EVERY_DAY_AT_MIDNIGHT),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SubscriptionSchedulerService.prototype, "checkExpiringSubscriptions", null);
__decorate([
    (0, schedule_1.Cron)(schedule_1.CronExpression.EVERY_HOUR),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SubscriptionSchedulerService.prototype, "handleExpiredSubscriptions", null);
__decorate([
    (0, schedule_1.Cron)(schedule_1.CronExpression.EVERY_DAY_AT_1AM),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SubscriptionSchedulerService.prototype, "processAutoRenewal", null);
exports.SubscriptionSchedulerService = SubscriptionSchedulerService = SubscriptionSchedulerService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        subscription_service_1.SubscriptionService])
], SubscriptionSchedulerService);
//# sourceMappingURL=subscription-scheduler.service.js.map