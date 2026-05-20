import { IsString, IsNotEmpty, IsOptional, IsNumber, IsBoolean } from 'class-validator';

export class CreateApiKeyDto {
  @IsString()
  @IsNotEmpty()
  provider: string;

  @IsString()
  @IsNotEmpty()
  apiKey: string;

  @IsString()
  @IsNotEmpty()
  model: string;

  @IsNumber()
  @IsOptional()
  rateLimitPerMin?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
