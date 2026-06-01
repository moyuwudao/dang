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
let PlanService = class PlanService {
    constructor(planRepo) {
        this.planRepo = planRepo;
    }
    async getPlans(includeInactive = false) {
        const where = includeInactive ? {} : { isActive: true };
        const plans = await this.planRepo.find({
            where,
            order: { priceCents: 'ASC' },
        });
        return plans.map(plan => ({
            ...plan,
            description: plan.description || `${plan.name} - 畅记云套餐`,
        }));
    }
    async getPlanById(planId) {
        const plan = await this.planRepo.findOne({ where: { id: planId } });
        if (!plan)
            return null;
        return {
            ...plan,
            description: plan.description || `${plan.name} - 畅记云套餐`,
        };
    }
    async createPlan(data) {
        if (!data.id) {
            data.id = (0, uuid_1.v4)();
        }
        const plan = this.planRepo.create(data);
        const saved = await this.planRepo.save(plan);
        return this.getPlanById(saved.id);
    }
    async updatePlan(planId, data) {
        await this.planRepo.update(planId, data);
        return this.getPlanById(planId);
    }
    async deletePlan(planId) {
        await this.planRepo.delete(planId);
        return { success: true };
    }
};
exports.PlanService = PlanService;
exports.PlanService = PlanService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], PlanService);
//# sourceMappingURL=plan.service.js.map