import { Controller, Post, Body, Get, Put, UseGuards, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, RefreshTokenDto, UpdateProfileDto, SendSmsCodeDto, SmsLoginDto } from './dto';
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
    
    return {
      code: 200,
      message: 'success',
      data: {
        captchaId,
        captchaUrl: `data:image/svg+xml;base64,${Buffer.from(
          `<svg xmlns="http://www.w3.org/2000/svg" width="120" height="40">
            <rect width="100%" height="100%" fill="#f0f0f0"/>
            <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" 
                  font-family="monospace" font-size="20" fill="#333">${captcha}</text>
          </svg>`
        ).toString('base64')}`,
        needCaptcha: true,
      },
    };
  }

  @Post('send-sms-code')
  async sendSmsCode(@Body() dto: SendSmsCodeDto) {
    return this.authService.sendSmsCode(dto.phone);
  }

  @Post('sms-login')
  async smsLogin(@Body() dto: SmsLoginDto) {
    return this.authService.smsLogin(dto);
  }
}