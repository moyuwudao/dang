import { IsString, IsOptional, IsNumber, IsBoolean, IsEnum, IsArray, IsDateString } from 'class-validator';
import { ApiKeyProvider, ApiKeyScope, ApiKeyStatus } from '../entities/api-key.entity';

export class CreateApiKeyDto {
  @IsEnum(ApiKeyProvider)
  provider: ApiKeyProvider;

  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  apiKey: string;

  @IsString()
  @IsOptional()
  apiSecret?: string;

  @IsString()
  model: string;

  @IsString()
  @IsOptional()
  baseUrl?: string;

  @IsEnum(ApiKeyStatus)
  @IsOptional()
  status?: ApiKeyStatus;

  @IsArray()
  @IsEnum(ApiKeyScope, { each: true })
  @IsOptional()
  scopes?: ApiKeyScope[];

  @IsNumber()
  @IsOptional()
  rateLimitPerMin?: number;

  @IsNumber()
  @IsOptional()
  maxConcurrentRequests?: number;

  @IsNumber()
  @IsOptional()
  dailyQuota?: number;

  @IsDateString()
  @IsOptional()
  expiresAt?: string;

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;

  @IsString()
  @IsOptional()
  allowedIpRanges?: string;
}
