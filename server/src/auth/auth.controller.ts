import { Controller, Post, Body, Get, Put, UseGuards, Req, Query } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, RefreshTokenDto, UpdateProfileDto, SendSmsCodeDto } from './dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    const data = await this.authService.register(dto);
    return { code: 200, message: 'success', data };
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const data = await this.authService.login(dto);
    return { code: 200, message: 'success', data };
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshTokenDto) {
    const data = await this.authService.refresh(dto.refreshToken);
    return { code: 200, message: 'success', data };
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  async logout(@Req() req) {
    await this.authService.logout(req.user.userId);
    return { code: 200, message: 'success', data: null };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Req() req) {
    const data = await this.authService.getProfile(req.user.sub);
    return { code: 200, message: 'success', data };
  }

  @Put('profile')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Req() req, @Body() dto: UpdateProfileDto) {
    const data = await this.authService.updateProfile(req.user.sub, dto);
    return { code: 200, message: 'success', data };
  }

  @Get('captcha')
  async getCaptcha() {
    const captcha = Math.random().toString(36).substring(2, 8).toUpperCase();
    const captchaId = Date.now().toString();
    
    const data = {
      captchaId,
      captchaUrl: `data:image/svg+xml;base64,${Buffer.from(
        `<svg xmlns="http://www.w3.org/2000/svg" width="120" height="40">
          <rect width="100%" height="100%" fill="#f0f0f0"/>
          <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" 
                font-family="monospace" font-size="20" fill="#333">${captcha}</text>
        </svg>`
      ).toString('base64')}`,
      needCaptcha: true,
    };
    
    return { code: 200, message: 'success', data };
  }

  @Post('send-sms-code')
  async sendSmsCode(@Body() dto: SendSmsCodeDto) {
    const data = {
      needCaptcha: false,
    };
    return { code: 200, message: '验证码已发送', data };
  }
}
