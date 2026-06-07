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
   * 业务层规范化：
   * 1. DB 中 allowedModels 是逗号分隔字符串，前端期望数组
   * 2. features 同理：DB 中存逗号分隔或 JSON 字符串，统一解析为数组
   * 3. defaultConfigs/apiPolicies 已是 jsonb，确保类型兜底
   */
  private normalizePlan(plan: Plan) {
    // features 解析：优先尝试 JSON.parse，失败再回退逗号分隔
    let features: string[] = [];
    if (plan.features) {
      const raw = String(plan.features).trim();
      if (raw.startsWith('[') || raw.startsWith('{')) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            features = parsed.map((f) => String(f));
          } else if (parsed && typeof parsed === 'object') {
            features = Object.values(parsed).map((f) => String(f));
          }
        } catch {
          // 不是合法 JSON，回退逗号分隔
          features = raw.split(/[,\n]/).map((s) => s.trim()).filter(Boolean);
        }
      } else {
        features = raw.split(/[,\n]/).map((s) => s.trim()).filter(Boolean);
      }
    }

    return {
      ...plan,
      allowedModels: plan.allowedModels
        ? String(plan.allowedModels).split(',').map(s => s.trim()).filter(Boolean)
        : [],
      features,
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
    if (Array.isArray(safeData.features)) {
      safeData.features = safeData.features.filter((f) => f).join(',');
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
    if (Array.isArray(safeData.features)) {
      safeData.features = safeData.features.filter((f) => f).join(',');
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
    const setSql = columns.map((c, i) => `"${this.toColumnName(c)}" = $${i + 1}`).join(', ');
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

  /**
   * entity 字段名 → 实际数据库列名
   * DB 中部分列名是驼峰风格（历史遗留），其余是 snake_case
   * 必须与 Plan entity 的 @Column({ name }) 完全一致
   */
  private toColumnName(field: string): string {
    // 这些字段在 plans 表中是驼峰列名（历史遗留）
    const camelCaseColumns = new Set([
      'isRecommended',
      'quotaType',
      'quotaValue',
      'features',
    ]);
    if (camelCaseColumns.has(field)) return field;
    return this.toSnakeCase(field);
  }

  async deletePlan(planId: string) {
    await this.planRepo.delete(planId);
    return { success: true };
  }
}
