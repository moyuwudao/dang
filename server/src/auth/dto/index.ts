import { IsString, IsOptional, MinLength, Matches } from 'class-validator';

export class RegisterDto {
  @IsString()
  @Matches(/^1[3-9]\d{9}$/, { message: '手机号格式不正确' })
  phone: string;

  @IsString()
  @MinLength(8, { message: '密码至少8位' })
  password: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: '验证码为6位数字' })
  smsCode: string;
}

export class LoginDto {
  @IsString()
  @Matches(/^1[3-9]\d{9}$/, { message: '手机号格式不正确' })
  phone: string;

  @IsString()
  @MinLength(8, { message: '密码至少8位' })
  password: string;
}

export class RefreshTokenDto {
  @IsString()
  refreshToken: string;
}

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  nickname?: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;
}
