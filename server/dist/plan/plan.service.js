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
var PlanService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlanService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const uuid_1 = require("uuid");
const plan_entity_1 = require("../subscription/entities/plan.entity");
let PlanService = PlanService_1 = class PlanService {
    constructor(planRepo) {
        this.planRepo = planRepo;
        this.logger = new common_1.Logger(PlanService_1.name);
    }
    async getPlans(includeInactive = false) {
        const where = includeInactive ? {} : { isActive: true };
        const plans = await this.planRepo.find({
            where,
            order: { priceCents: 'ASC' },
        });
        return plans.map(plan => this.normalizePlan(plan));
    }
    async getPlanById(planId) {
        const plan = await this.planRepo.findOne({ where: { id: planId } });
        if (!plan)
            return null;
        return this.normalizePlan(plan);
    }
    normalizePlan(plan) {
        let features = [];
        if (plan.features) {
            const raw = String(plan.features).trim();
            if (raw.startsWith('[') || raw.startsWith('{')) {
                try {
                    const parsed = JSON.parse(raw);
                    if (Array.isArray(parsed)) {
                        features = parsed.map((f) => String(f));
                    }
                    else if (parsed && typeof parsed === 'object') {
                        features = Object.values(parsed).map((f) => String(f));
                    }
                }
                catch {
                    features = raw.split(/[,\n]/).map((s) => s.trim()).filter(Boolean);
                }
            }
            else {
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
    async createPlan(data) {
        if (!data.id) {
            data.id = (0, uuid_1.v4)();
        }
        const safeData = { ...data };
        if (Array.isArray(safeData.allowedModels)) {
            safeData.allowedModels = safeData.allowedModels.filter((m) => m).join(',');
        }
        if (Array.isArray(safeData.features)) {
            safeData.features = safeData.features.filter((f) => f).join(',');
        }
        const plan = this.planRepo.create(safeData);
        const saved = await this.planRepo.save(plan);
        return this.getPlanById(saved.id);
    }
    async updatePlan(planId, data) {
        const safeData = { ...data };
        if (Array.isArray(safeData.allowedModels)) {
            safeData.allowedModels = safeData.allowedModels.filter((m) => m).join(',');
        }
        if (Array.isArray(safeData.features)) {
            safeData.features = safeData.features.filter((f) => f).join(',');
        }
        delete safeData.id;
        delete safeData.createdAt;
        delete safeData.defaultConfigs;
        delete safeData.apiPolicies;
        const columns = Object.keys(safeData).filter((k) => safeData[k] !== undefined);
        if (columns.length === 0 && data.defaultConfigs === undefined && data.apiPolicies === undefined) {
            return this.getPlanById(planId);
        }
        const setSql = columns.map((c, i) => `"${this.toColumnName(c)}" = $${i + 1}`).join(', ');
        const values = columns.map((c) => safeData[c]);
        const setParts = [];
        if (setSql)
            setParts.push(setSql);
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
    toSnakeCase(str) {
        return str.replace(/[A-Z]/g, (c) => '_' + c.toLowerCase());
    }
    toColumnName(field) {
        const camelCaseColumns = new Set([
            'isRecommended',
            'quotaType',
            'quotaValue',
            'features',
        ]);
        if (camelCaseColumns.has(field))
            return field;
        return this.toSnakeCase(field);
    }
    async deletePlan(planId) {
        await this.planRepo.delete(planId);
        return { success: true };
    }
};
exports.PlanService = PlanService;
exports.PlanService = PlanService = PlanService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], PlanService);
//# sourceMappingURL=plan.service.js.map