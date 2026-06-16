import { Controller, Post, Body } from '@nestjs/common';
import { AdminAuthService } from './admin-auth.service';
import { AuthService } from '../auth/auth.service';

@Controller('admin')
export class AdminAuthController {
  constructor(
    private readonly adminAuthService: AdminAuthService,
    private readonly authService: AuthService,
  ) {}

  // 管理员登录：手机号 + 密码 + 短信验证码
  @Post('login')
  async login(@Body() body: { phone: string; password: string; smsCode: string }) {
    if (!body.phone || !body.password || !body.smsCode) {
      return {
        code: 400,
        message: '请提供手机号、密码和短信验证码',
        data: null,
      };
    }
    return this.adminAuthService.login(body.phone, body.password, body.smsCode);
  }

  // 管理员获取图片验证码（复用 auth 的 captcha）
  @Post('send-sms-code')
  async sendSmsCode(@Body() body: { phone: string; captchaId: string; captcha: string }) {
    if (!body.phone || !body.captchaId || !body.captcha) {
      return {
        code: 400,
        message: '请提供手机号、图片验证码ID和图片验证码',
        data: null,
      };
    }
    return this.adminAuthService.sendSmsCode(body.phone, body.captchaId, body.captcha);
  }
}
