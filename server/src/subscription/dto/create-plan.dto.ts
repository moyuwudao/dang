import { IsString, IsNumber, IsOptional, IsBoolean, IsNotEmpty, IsArray } from 'class-validator';

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
}
