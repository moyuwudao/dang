import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Plan } from '../subscription/entities/plan.entity';

@Injectable()
export class PlanService {
  private readonly logger = new Logger(PlanService.name);

  constructor(
    @InjectRepository(Plan)
    private planRepo: Repository<Plan>,
  ) {}

  async getPlans(includeInactive = false) {
    const where = includeInactive ? {} : { isActive: true };
    const plans = await this.planRepo.find({
      where,
      order: { priceCents: 'ASC' },
    });

    return plans.map(plan => this.normalizePlan(plan));
  }

  async getPlanById(planId: string) {
    const plan = await this.planRepo.findOne({ where: { id: planId } });
    if (!plan) return null;
    return this.normalizePlan(plan);
  }

  /**
   * 业务层规范化：DB 中 allowedModels 是逗号分隔字符串，前端期望数组
   */
  private normalizePlan(plan: Plan) {
    return {
      ...plan,
      allowedModels: plan.allowedModels
        ? String(plan.allowedModels).split(',').map(s => s.trim()).filter(Boolean)
        : [],
      defaultConfigs: plan.defaultConfigs || {},
      apiPolicies: Array.isArray(plan.apiPolicies) ? plan.apiPolicies : [],
      description: plan.description || `${plan.name} - 畅记云套餐`,
    };
  }

  async createPlan(data: Partial<Plan>) {
    if (!data.id) {
      data.id = uuidv4();
    }
    const safeData: any = { ...data };
    if (Array.isArray(safeData.allowedModels)) {
      safeData.allowedModels = safeData.allowedModels.filter((m) => m).join(',');
    }
    const plan = this.planRepo.create(safeData as Plan);
    const saved = await this.planRepo.save(plan);
    return this.getPlanById((saved as any).id);
  }

  async updatePlan(planId: string, data: Partial<Plan>) {
    // 全部 raw SQL，绕过 TypeORM metadata
    const safeData: any = { ...data };
    if (Array.isArray(safeData.allowedModels)) {
      safeData.allowedModels = safeData.allowedModels.filter((m) => m).join(',');
    }
    delete safeData.id;
    delete safeData.createdAt;
    delete safeData.defaultConfigs; // jsonb 单独处理
    delete safeData.apiPolicies;    // jsonb 单独处理

    const columns = Object.keys(safeData).filter((k) => safeData[k] !== undefined);
    if (columns.length === 0 && data.defaultConfigs === undefined && data.apiPolicies === undefined) {
      return this.getPlanById(planId);
    }

    // 用 raw query 构造 SET 子句（参数化防注入）
    const setSql = columns.map((c, i) => `"${this.toSnakeCase(c)}" = $${i + 1}`).join(', ');
    const values = columns.map((c) => safeData[c]);

    const setParts: string[] = [];
    if (setSql) setParts.push(setSql);

    if (data.defaultConfigs !== undefined) {
      const defaultConfigJson = JSON.stringify(data.defaultConfigs);
      values.push(defaultConfigJson);
      setParts.push(`"default_configs" = $${values.length}::jsonb`);
    }

    if (data.apiPolicies !== undefined) {
      const apiPoliciesJson = JSON.stringify(data.apiPolicies);
      values.push(apiPoliciesJson);
      setParts.push(`"api_policies" = $${values.length}::jsonb`);
    }

    values.push(planId);
    const sql = `UPDATE plans SET ${setParts.join(', ')} WHERE id = $${values.length}`;
    await this.planRepo.query(sql, values);
    return this.getPlanById(planId);
  }

  private toSnakeCase(str: string): string {
    return str.replace(/[A-Z]/g, (c) => '_' + c.toLowerCase());
  }

  async deletePlan(planId: string) {
    await this.planRepo.delete(planId);
    return { success: true };
  }
}
