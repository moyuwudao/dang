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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlanService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const uuid_1 = require("uuid");
const plan_entity_1 = require("../subscription/entities/plan.entity");
const plan_api_policy_entity_1 = require("../subscription/entities/plan-api-policy.entity");
const plan_feature_quota_entity_1 = require("../subscription/entities/plan-feature-quota.entity");
let PlanService = class PlanService {
    constructor(planRepo, planApiPolicyRepo, planFeatureQuotaRepo) {
        this.planRepo = planRepo;
        this.planApiPolicyRepo = planApiPolicyRepo;
        this.planFeatureQuotaRepo = planFeatureQuotaRepo;
    }
    async getPlans(includeInactive = false) {
        const where = includeInactive ? {} : { isActive: true };
        const plans = await this.planRepo.find({
            where,
            order: { priceCents: 'ASC' },
        });
        return this.enrichPlansWithModels(plans);
    }
    async getPlanById(planId) {
        const plan = await this.planRepo.findOne({ where: { id: planId } });
        if (!plan)
            return null;
        const enriched = await this.enrichPlansWithModels([plan]);
        return enriched[0];
    }
    async createPlan(data) {
        if (!data.id) {
            data.id = (0, uuid_1.v4)();
        }
        const { featureQuotas, ...planData } = data;
        const plan = this.planRepo.create(planData);
        const savedPlan = await this.planRepo.save(plan);
        if (featureQuotas && featureQuotas.length > 0) {
            const quotas = featureQuotas.map(q => ({
                planId: savedPlan.id,
                featureType: q.featureType,
                quotaValue: q.quotaValue,
                quotaUnit: q.quotaUnit,
                multiplier: q.multiplier || 1.0,
            }));
            await this.planFeatureQuotaRepo.save(quotas);
        }
        return this.getPlanById(savedPlan.id);
    }
    async updatePlan(planId, data) {
        const { featureQuotas, ...planData } = data;
        await this.planRepo.update(planId, planData);
        if (featureQuotas) {
            await this.planFeatureQuotaRepo.delete({ planId });
            if (featureQuotas.length > 0) {
                const quotas = featureQuotas.map(q => ({
                    planId,
                    featureType: q.featureType,
                    quotaValue: q.quotaValue,
                    quotaUnit: q.quotaUnit,
                    multiplier: q.multiplier || 1.0,
                }));
                await this.planFeatureQuotaRepo.save(quotas);
            }
        }
        return this.getPlanById(planId);
    }
    async deletePlan(planId) {
        await this.planFeatureQuotaRepo.delete({ planId });
        await this.planRepo.delete(planId);
        return { success: true };
    }
    async getPlanFeatureQuotas(planId) {
        return this.planFeatureQuotaRepo.find({
            where: { planId },
            order: { featureType: 'ASC' },
        });
    }
    async setPlanFeatureQuota(planId, data) {
        let quota = await this.planFeatureQuotaRepo.findOne({
            where: { planId, featureType: data.featureType },
        });
        if (quota) {
            quota.quotaValue = data.quotaValue;
            quota.quotaUnit = data.quotaUnit;
            quota.multiplier = data.multiplier || 1.0;
        }
        else {
            quota = this.planFeatureQuotaRepo.create({
                planId,
                featureType: data.featureType,
                quotaValue: data.quotaValue,
                quotaUnit: data.quotaUnit,
                multiplier: data.multiplier || 1.0,
            });
        }
        return this.planFeatureQuotaRepo.save(quota);
    }
    async deletePlanFeatureQuota(quotaId) {
        await this.planFeatureQuotaRepo.delete(quotaId);
        return { success: true };
    }
    async enrichPlansWithModels(plans) {
        const plansWithModels = await Promise.all(plans.map(async (plan) => {
            const policies = await this.planApiPolicyRepo.find({
                where: { planId: plan.id },
            });
            const featureQuotas = await this.planFeatureQuotaRepo.find({
                where: { planId: plan.id },
            });
            const allowedModels = policies
                .filter(p => p.modelPattern && p.modelPattern !== '*')
                .map(p => p.modelPattern);
            return {
                ...plan,
                allowedModels: Array.from(new Set(allowedModels)),
                featureQuotas,
            };
        }));
        return plansWithModels;
    }
};
exports.PlanService = PlanService;
exports.PlanService = PlanService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __param(1, (0, typeorm_1.InjectRepository)(plan_api_policy_entity_1.PlanApiPolicy)),
    __param(2, (0, typeorm_1.InjectRepository)(plan_feature_quota_entity_1.PlanFeatureQuota)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], PlanService);
//# sourceMappingURL=plan.service.js.map