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
    
    // 生成 SVG 图片验证码
    const svg = this.generateCaptchaSvg(captcha);
    const captchaUrl = 'data:image/svg+xml;base64,' + Buffer.from(svg).toString('base64');
    
    return {
      code: 200,
      message: 'success',
      data: {
        captchaId,
        captchaUrl,
        needCaptcha: true,
      },
    };
  }

  private generateCaptchaSvg(text: string): string {
    const width = 120;
    const height = 40;
    const chars = text.split('');
    const charWidth = width / chars.length;
    
    let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`;
    svg += `<rect width="100%" height="100%" fill="#f5f5f5"/>`;
    
    // 添加干扰线
    for (let i = 0; i < 5; i++) {
      const x1 = Math.random() * width;
      const y1 = Math.random() * height;
      const x2 = Math.random() * width;
      const y2 = Math.random() * height;
      svg += `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#ddd" stroke-width="1"/>`;
    }
    
    // 添加文字
    chars.forEach((char, index) => {
      const x = index * charWidth + charWidth / 2;
      const y = height / 2 + 5;
      const rotate = (Math.random() - 0.5) * 30;
      const fontSize = 20 + Math.random() * 8;
      svg += `<text x="${x}" y="${y}" font-family="Arial" font-size="${fontSize}" fill="#333" text-anchor="middle" dominant-baseline="middle" transform="rotate(${rotate}, ${x}, ${y})">${char}</text>`;
    });
    
    svg += '</svg>';
    return svg;
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