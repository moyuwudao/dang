import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Plan } from '../subscription/entities/plan.entity';

@Injectable()
export class PlanService {
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

    return plans.map(plan => ({
      ...plan,
      description: plan.description || `${plan.name} - 畅记云套餐`,
    }));
  }

  async getPlanById(planId: string) {
    const plan = await this.planRepo.findOne({ where: { id: planId } });
    if (!plan) return null;
    return {
      ...plan,
      description: plan.description || `${plan.name} - 畅记云套餐`,
    };
  }

  async createPlan(data: Partial<Plan>) {
    if (!data.id) {
      data.id = uuidv4();
    }
    const plan = this.planRepo.create(data);
    const saved = await this.planRepo.save(plan);
    return this.getPlanById(saved.id);
  }

  async updatePlan(planId: string, data: Partial<Plan>) {
    await this.planRepo.update(planId, data);
    return this.getPlanById(planId);
  }

  async deletePlan(planId: string) {
    await this.planRepo.delete(planId);
    return { success: true };
  }
}
