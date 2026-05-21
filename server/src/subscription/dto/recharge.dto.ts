import { IsNumber, IsString, IsOptional, IsNotEmpty, Min } from 'class-validator';

export class RechargeDto {
  @IsNumber()
  @Min(1)
  @IsNotEmpty()
  amountCents: number;

  @IsString()
  @IsOptional()
  paymentMethod?: string;
}

export class RefundDto {
  @IsNumber()
  @Min(1)
  @IsNotEmpty()
  amountCents: number;

  @IsString()
  @IsOptional()
  reason?: string;
}
