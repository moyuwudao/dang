import { IsString, IsNumber, IsOptional, IsBoolean, IsNotEmpty } from 'class-validator';

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
  @IsNotEmpty()
  quotaType: string;

  @IsNumber()
  @IsOptional()
  quotaValue?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
