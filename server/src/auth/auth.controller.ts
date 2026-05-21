import { Controller, Post, Body, Get, Put, UseGuards, Req, Query } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, RefreshTokenDto, UpdateProfileDto, SendSmsCodeDto } from './dto';
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

  @Put('profile')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Req() req, @Body() dto: UpdateProfileDto) {
    return this.authService.updateProfile(req.user.sub, dto);
  }

  // 图形验证码接口（简化版，实际生产环境应使用图片生成库）
  @Get('captcha')
  async getCaptcha() {
    // 生成随机验证码
    const captcha = Math.random().toString(36).substring(2, 8).toUpperCase();
    const captchaId = Date.now().toString();
    
    // 实际生产环境应该：
    // 1. 将验证码存入 Redis，设置过期时间（5分钟）
    // 2. 使用 svg-captcha 或类似库生成图片
    // 3. 返回图片 base64 或图片 URL
    
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

  // 发送短信验证码
  @Post('send-sms-code')
  async sendSmsCode(@Body() dto: SendSmsCodeDto) {
    // 实际生产环境应该：
    // 1. 验证图形验证码（如果有）
    // 2. 检查发送频率限制
    // 3. 调用短信服务商发送验证码
    // 4. 将验证码存入 Redis，设置过期时间（5分钟）
    
    // 简化版：直接返回成功（实际应接入短信服务）
    return {
      code: 200,
      message: '验证码已发送',
      data: {
        needCaptcha: false,
      },
    };
  }
}
