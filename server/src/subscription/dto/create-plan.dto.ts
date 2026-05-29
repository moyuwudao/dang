import { IsString, IsNumber, IsOptional, IsBoolean, IsNotEmpty, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class PlanFeatureQuotaDto {
  @IsString()
  @IsNotEmpty()
  featureType: string;

  @IsNumber()
  @IsNotEmpty()
  quotaValue: number;

  @IsString()
  @IsNotEmpty()
  quotaUnit: string;

  @IsNumber()
  @IsOptional()
  multiplier?: number;
}

export class CreatePlanDto {
  @IsString()
  @IsNotEmpty()
  id: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber()
  @IsNotEmpty()
  priceCents: number;

  @IsNumber()
  @IsNotEmpty()
  durationDays: number;

  @IsString()
  @IsOptional()
  type?: string; // subscription | package | recharge

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  features?: string[];

  @IsBoolean()
  @IsOptional()
  isRecommended?: boolean;

  @IsString()
  @IsNotEmpty()
  quotaType: string;

  @IsNumber()
  @IsOptional()
  quotaValue?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  allowedModels?: string[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PlanFeatureQuotaDto)
  @IsOptional()
  featureQuotas?: PlanFeatureQuotaDto[];
}
