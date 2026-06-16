import { Injectable, Logger, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { Redis } from 'ioredis';
import { User } from './entities/user.entity';
import { RegisterDto, LoginDto, UpdateProfileDto, SmsLoginDto, ChangePasswordDto } from './dto';
import { SubscriptionService } from '../subscription/subscription.service';
import { SmsService } from './sms.service';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private redisClient: Redis;

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
    private subscriptionService: SubscriptionService,
    private smsService: SmsService,
  ) {
    this.redisClient = new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || process.env.REDIS_PASS || 'Redis123456',
    });
    // 防止 ioredis unhandled error event 导致进程崩溃（异常5+6修复）
    this.redisClient.on('error', (err) => {
      this.logger.warn(`Redis client error (non-fatal): ${err.message}`);
    });
  }

  async register(dto: RegisterDto) {
    // 验证短信验证码
    const storedCode = await this.redisClient.get(`sms_code:${dto.phone}`);
    if (!storedCode) {
      throw new BadRequestException('验证码已过期，请重新获取');
    }
    if (storedCode !== dto.smsCode) {
      throw new BadRequestException('验证码错误');
    }
    // 验证通过后删除验证码，防止重用
    await this.redisClient.del(`sms_code:${dto.phone}`);

    const existingUser = await this.userRepository.findOne({
      where: { phone: dto.phone },
    });

    if (existingUser) {
      throw new BadRequestException('手机号已注册');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const user = this.userRepository.create({
      phone: dto.phone,
      passwordHash,
    });

    await this.userRepository.save(user);

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    await this.subscriptionService.createTrialSubscription(user.id, {
      planId: 'trial',
      planName: '新手体验包',
      totalQuota: 100000,
      usedQuota: 0,
      expiresAt,
    });

    const tokens = await this.generateTokens(user);

    return {
      code: 200,
      message: '注册成功',
      data: {
        user: this.sanitizeUser(user),
        ...tokens,
      },
    };
  }

  async login(dto: LoginDto) {
    const user = await this.userRepository.findOne({
      where: { phone: dto.phone },
    });

    if (!user) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    if (user.status !== 'active') {
      throw new UnauthorizedException('账户已被禁用');
    }

    // 记录登录信息
    await this.userRepository.update(user.id, {
      lastLoginAt: new Date(),
    });

    const tokens = await this.generateTokens(user);

    return {
      code: 200,
      message: '登录成功',
      data: {
        user: this.sanitizeUser(user),
        ...tokens,
      },
    };
  }

  // 存储图片验证码
  async setCaptcha(captchaId: string, captcha: string) {
    await this.redisClient.set(`captcha:${captchaId}`, captcha, 'EX', 300);
  }

  // 验证图片验证码
  async verifyCaptcha(captchaId: string, captcha: string): Promise<boolean> {
    const stored = await this.redisClient.get(`captcha:${captchaId}`);
    if (!stored) return false;
    const valid = stored.toUpperCase() === captcha.toUpperCase();
    if (valid) {
      await this.redisClient.del(`captcha:${captchaId}`);
    }
    return valid;
  }

  // 发送短信验证码
  async sendSmsCode(phone: string, captchaId?: string, captcha?: string) {
    // 验证图片验证码
    if (captchaId && captcha) {
      const valid = await this.verifyCaptcha(captchaId, captcha);
      if (!valid) {
        throw new BadRequestException('图片验证码错误或已过期');
      }
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    await this.redisClient.set(`sms_code:${phone}`, code, 'EX', 300);

    try {
      await this.smsService.sendVerificationCode(phone, code);
      this.logger.log(`SMS sent successfully to ${phone}`);
      return {
        code: 200,
        message: '验证码已发送',
        data: { expiresIn: 300 },
      };
    } catch (e) {
      const errorMsg = e?.message || String(e);
      this.logger.error(`SMS send failed for ${phone}: ${errorMsg}`);
      // 删除已写入 Redis 的无效验证码
      await this.redisClient.del(`sms_code:${phone}`);
      throw new BadRequestException(`短信发送失败: ${errorMsg}`);
    }
  }

  async smsLogin(dto: SmsLoginDto) {
    const storedCode = await this.redisClient.get(`sms_code:${dto.phone}`);

    if (!storedCode) {
      throw new BadRequestException('验证码已过期，请重新获取');
    }

    if (storedCode !== dto.smsCode) {
      throw new BadRequestException('验证码错误');
    }

    await this.redisClient.del(`sms_code:${dto.phone}`);

    let user = await this.userRepository.findOne({
      where: { phone: dto.phone },
    });

    if (!user) {
      user = this.userRepository.create({
        phone: dto.phone,
        passwordHash: '',
      });
      await this.userRepository.save(user);

      const now = new Date();
      const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

      await this.subscriptionService.createTrialSubscription(user.id, {
        planId: 'trial',
        planName: '新手体验包',
        totalQuota: 100000,
        usedQuota: 0,
        expiresAt,
      });
    }

    if (user.status !== 'active') {
      throw new UnauthorizedException('账户已被禁用');
    }

    // 记录登录信息
    await this.userRepository.update(user.id, {
      lastLoginAt: new Date(),
    });

    const tokens = await this.generateTokens(user);

    return {
      code: 200,
      message: '登录成功',
      data: {
        user: this.sanitizeUser(user),
        ...tokens,
      },
    };
  }

  async refresh(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
      });

      const user = await this.userRepository.findOne({
        where: { id: payload.sub },
      });

      if (!user || user.status !== 'active') {
        throw new UnauthorizedException('用户不存在或已被禁用');
      }

      return {
        code: 200,
        message: '刷新成功',
        data: await this.generateTokens(user),
      };
    } catch {
      throw new UnauthorizedException('刷新令牌无效');
    }
  }

  async logout(userId: string) {
    return {
      code: 200,
      message: '登出成功',
      data: null,
    };
  }

  async getProfile(userId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new UnauthorizedException('用户不存在');
    }

    return {
      code: 200,
      message: 'success',
      data: {
        user: this.sanitizeUser(user),
      },
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    await this.userRepository.update(userId, {
      nickname: dto.nickname,
      avatarUrl: dto.avatarUrl,
    });

    return {
      code: 200,
      message: '更新成功',
      data: null,
    };
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new UnauthorizedException('用户不存在');
    }

    // 判断用户是否有密码（短信登录注册的用户密码为空字符串）
    const hasPassword = user.passwordHash && user.passwordHash.length > 0;

    if (hasPassword && dto.oldPassword) {
      // 方案1：已知旧密码 - 验证旧密码
      const isValid = await bcrypt.compare(dto.oldPassword, user.passwordHash);
      if (!isValid) {
        throw new UnauthorizedException('旧密码错误');
      }
    } else if (dto.smsCode) {
      // 方案2：忘记旧密码 - 验证短信验证码
      const storedCode = await this.redisClient.get(`sms_code:${dto.phone}`);
      if (!storedCode) {
        throw new BadRequestException('验证码已过期，请重新获取');
      }
      if (storedCode !== dto.smsCode) {
        throw new BadRequestException('验证码错误');
      }
      await this.redisClient.del(`sms_code:${dto.phone}`);
    } else {
      // 既没有旧密码也没有短信验证码
      throw new BadRequestException('请提供旧密码或短信验证码');
    }

    // 更新密码
    const newPasswordHash = await bcrypt.hash(dto.newPassword, 12);
    await this.userRepository.update(userId, { passwordHash: newPasswordHash });

    return {
      code: 200,
      message: '密码修改成功',
      data: null,
    };
  }

  private async generateTokens(user: User) {
    const payload = { sub: user.id, phone: user.phone, role: user.role };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
      expiresIn: '30d',
    });

    return { accessToken, refreshToken };
  }

  private sanitizeUser(user: User) {
    const { passwordHash, ...result } = user as any;
    return {
      ...result,
      hasPassword: passwordHash && passwordHash.length > 0,
    };
  }
}