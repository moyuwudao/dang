import { Plan } from './plan.entity';
export declare class PlanApiPolicy {
    id: string;
    planId: string;
    provider: string;
    modelPattern: string;
    multiplier: number;
    isAllowed: boolean;
    plan: Plan;
    createdAt: Date;
}
