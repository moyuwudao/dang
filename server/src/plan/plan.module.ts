import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlanService } from './plan.service';
import { Plan } from '../subscription/entities/plan.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Plan])],
  providers: [PlanService],
  exports: [PlanService],
})
export class PlanModule {}
