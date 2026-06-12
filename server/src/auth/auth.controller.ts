import { Controller, Post, Body, Get, Put, UseGuards, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, RefreshTokenDto, UpdateProfileDto, SendSmsCodeDto, SmsLoginDto, ChangePasswordDto } from './dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  async logout(@Req() req) {
    return this.authService.logout(req.user.userId);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Req() req) {
    return this.authService.getProfile(req.user.sub);
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  async getProfileByPath(@Req() req) {
    return this.authService.getProfile(req.user.sub);
  }

  @Put('profile')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Req() req, @Body() dto: UpdateProfileDto) {
    return this.authService.updateProfile(req.user.sub, dto);
  }

  @Get('captcha')
  async getCaptcha() {
    const captcha = Math.random().toString(36).substring(2, 8).toUpperCase();
    const captchaId = Date.now().toString();
    
    // 将验证码存入 Redis，5分钟过期
    await this.authService.setCaptcha(captchaId, captcha);
    
    return {
      code: 200,
      message: 'success',
      data: {
        captchaId,
        captchaText: captcha,  // 直接返回文本，客户端显示为文字验证码
        needCaptcha: true,
      },
    };
  }

  @Post('send-sms-code')
  async sendSmsCode(@Body() dto: SendSmsCodeDto) {
    return this.authService.sendSmsCode(dto.phone, dto.captchaId, dto.captcha);
  }

  @Post('sms-login')
  async smsLogin(@Body() dto: SmsLoginDto) {
    return this.authService.smsLogin(dto);
  }

  @Post('change-password')
  @UseGuards(JwtAuthGuard)
  async changePassword(@Req() req, @Body() dto: ChangePasswordDto) {
    return this.authService.changePassword(req.user.sub, dto);
  }
}