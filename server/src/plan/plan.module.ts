import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlanService } from './plan.service';
import { Plan } from '../subscription/entities/plan.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';
import { PlanFeatureQuota } from '../subscription/entities/plan-feature-quota.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Plan, PlanApiPolicy, PlanFeatureQuota])],
  providers: [PlanService],
  exports: [PlanService],
})
export class PlanModule {}
