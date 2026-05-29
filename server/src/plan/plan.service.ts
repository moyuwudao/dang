import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Plan } from '../subscription/entities/plan.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';
import { PlanFeatureQuota } from '../subscription/entities/plan-feature-quota.entity';

@Injectable()
export class PlanService {
  constructor(
    @InjectRepository(Plan)
    private planRepo: Repository<Plan>,
    @InjectRepository(PlanApiPolicy)
    private planApiPolicyRepo: Repository<PlanApiPolicy>,
    @InjectRepository(PlanFeatureQuota)
    private planFeatureQuotaRepo: Repository<PlanFeatureQuota>,
  ) {}

  async getPlans(includeInactive = false) {
    const where = includeInactive ? {} : { isActive: true };
    const plans = await this.planRepo.find({
      where,
      order: { priceCents: 'ASC' },
    });

    return this.enrichPlansWithModels(plans);
  }

  async getPlanById(planId: string) {
    const plan = await this.planRepo.findOne({ where: { id: planId } });
    if (!plan) return null;

    const enriched = await this.enrichPlansWithModels([plan]);
    return enriched[0];
  }

  async createPlan(data: Partial<Plan> & { featureQuotas?: any[] }) {
    if (!data.id) {
      data.id = uuidv4();
    }
    const { featureQuotas, ...planData } = data;
    const plan = this.planRepo.create(planData);
    const savedPlan = await this.planRepo.save(plan);

    // 创建功能配额
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

  async updatePlan(planId: string, data: Partial<Plan> & { featureQuotas?: any[] }) {
    const { featureQuotas, ...planData } = data;
    await this.planRepo.update(planId, planData);

    // 更新功能配额
    if (featureQuotas) {
      // 删除旧配额
      await this.planFeatureQuotaRepo.delete({ planId });
      
      // 创建新配额
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

  async deletePlan(planId: string) {
    // 删除功能配额
    await this.planFeatureQuotaRepo.delete({ planId });
    await this.planRepo.delete(planId);
    return { success: true };
  }

  // 获取套餐功能配额
  async getPlanFeatureQuotas(planId: string) {
    return this.planFeatureQuotaRepo.find({
      where: { planId },
      order: { featureType: 'ASC' },
    });
  }

  // 设置套餐功能配额
  async setPlanFeatureQuota(planId: string, data: {
    featureType: string;
    quotaValue: number;
    quotaUnit: string;
    multiplier?: number;
  }) {
    let quota = await this.planFeatureQuotaRepo.findOne({
      where: { planId, featureType: data.featureType },
    });

    if (quota) {
      quota.quotaValue = data.quotaValue;
      quota.quotaUnit = data.quotaUnit;
      quota.multiplier = data.multiplier || 1.0;
    } else {
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

  // 删除套餐功能配额
  async deletePlanFeatureQuota(quotaId: string) {
    await this.planFeatureQuotaRepo.delete(quotaId);
    return { success: true };
  }

  private async enrichPlansWithModels(plans: Plan[]) {
    const plansWithModels = await Promise.all(
      plans.map(async (plan) => {
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
      }),
    );
    return plansWithModels;
  }
}
