import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { Redis } from 'ioredis';
import { User } from './entities/user.entity';
import { RegisterDto, LoginDto, UpdateProfileDto, SmsLoginDto } from './dto';
import { SubscriptionService } from '../subscription/subscription.service';
import { SmsService } from './sms.service';

@Injectable()
export class AuthService {
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
      password: process.env.REDIS_PASSWORD || process.env.REDIS_PASS,
    });
  }

  async register(dto: RegisterDto) {
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
    await this.subscriptionService.initUserBalance(user.id);

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    
    await this.subscriptionService.createTrialSubscription(user.id, {
      planId: 'trial',
      planName: '新手体验包',
      totalQuota: 100,
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

  async sendSmsCode(phone: string): Promise<{ code: number; message: string; data: { needCaptcha: boolean } }> {
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    await this.redisClient.set(`sms_code:${phone}`, code, 'EX', 300);

    try {
      await this.smsService.sendVerificationCode(phone);
      return {
        code: 200,
        message: '验证码已发送',
        data: { needCaptcha: false },
      };
    } catch {
      return {
        code: 200,
        message: '验证码已发送',
        data: { needCaptcha: false },
      };
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
      await this.subscriptionService.initUserBalance(user.id);

      const now = new Date();
      const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
      
      await this.subscriptionService.createTrialSubscription(user.id, {
        planId: 'trial',
        planName: '新手体验包',
        totalQuota: 100,
        usedQuota: 0,
        expiresAt,
      });
    }

    if (user.status !== 'active') {
      throw new UnauthorizedException('账户已被禁用');
    }

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
      data: this.sanitizeUser(user),
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

  private async generateTokens(user: User) {
    const payload = { sub: user.id, phone: user.phone, role: user.role };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
      expiresIn: '7d',
    });

    return { accessToken, refreshToken };
  }

  private sanitizeUser(user: User) {
    const { passwordHash, ...result } = user as any;
    return result;
  }
}