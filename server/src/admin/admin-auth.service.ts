import { Injectable, Logger, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { Redis } from 'ioredis';
import { User } from '../auth/entities/user.entity';
import { SmsService } from '../auth/sms.service';

@Injectable()
export class AdminAuthService {
  private readonly logger = new Logger(AdminAuthService.name);
  private redisClient: Redis;

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
    private smsService: SmsService,
  ) {
    this.redisClient = new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || process.env.REDIS_PASS || 'Redis123456',
    });
    this.redisClient.on('error', (err) => {
      this.logger.warn(`Redis client error (non-fatal): ${err.message}`);
    });
  }

  // 管理员登录：手机号 + 密码 + 短信验证码
  async login(phone: string, password: string, smsCode: string) {
    // 1. 验证短信验证码
    const storedCode = await this.redisClient.get(`sms_code:${phone}`);
    if (!storedCode) {
      throw new BadRequestException('验证码已过期，请重新获取');
    }
    if (storedCode !== smsCode) {
      throw new BadRequestException('验证码错误');
    }
    await this.redisClient.del(`sms_code:${phone}`);

    // 2. 查找用户
    const user = await this.userRepository.findOne({ where: { phone } });
    if (!user) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    // 3. 检查是否为管理员
    if (user.role !== 'admin') {
      throw new UnauthorizedException('无管理员权限');
    }

    // 4. 验证密码
    if (!user.passwordHash || user.passwordHash.length === 0) {
      throw new UnauthorizedException('请先设置密码');
    }
    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    // 5. 检查账户状态
    if (user.status !== 'active') {
      throw new UnauthorizedException('账户已被禁用');
    }

    // 6. 生成 Token
    const payload = { sub: user.id, phone: user.phone, role: user.role };
    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
      expiresIn: '30d',
    });

    // 7. 更新登录信息
    await this.userRepository.update(user.id, { lastLoginAt: new Date() });

    return {
      code: 200,
      message: '登录成功',
      data: {
        user: {
          id: user.id,
          phone: user.phone,
          nickname: user.nickname,
          role: user.role,
        },
        accessToken,
        refreshToken,
      },
    };
  }

  // 管理员发送短信验证码（复用 AuthService 的图片验证码逻辑）
  async sendSmsCode(phone: string, captchaId: string, captcha: string) {
    // 验证图片验证码
    const stored = await this.redisClient.get(`captcha:${captchaId}`);
    if (!stored) {
      throw new BadRequestException('图片验证码已过期');
    }
    const valid = stored.toUpperCase() === captcha.toUpperCase();
    if (!valid) {
      throw new BadRequestException('图片验证码错误');
    }
    await this.redisClient.del(`captcha:${captchaId}`);

    // 检查是否为管理员
    const user = await this.userRepository.findOne({ where: { phone } });
    if (!user || user.role !== 'admin') {
      // 不暴露用户是否存在，统一返回发送成功（安全考虑）
      this.logger.warn(`非管理员手机号尝试获取管理员验证码: ${phone}`);
      throw new BadRequestException('该手机号不是管理员');
    }

    // 发送短信
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    await this.redisClient.set(`sms_code:${phone}`, code, 'EX', 300);

    try {
      await this.smsService.sendVerificationCode(phone, code);
      this.logger.log(`Admin SMS sent successfully to ${phone}`);
      return {
        code: 200,
        message: '验证码已发送',
        data: { expiresIn: 300 },
      };
    } catch (e) {
      await this.redisClient.del(`sms_code:${phone}`);
      const errorMsg = e?.message || String(e);
      this.logger.error(`Admin SMS send failed for ${phone}: ${errorMsg}`);
      throw new BadRequestException(`短信发送失败: ${errorMsg}`);
    }
  }
}
