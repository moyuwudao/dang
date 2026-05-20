import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User } from './entities/user.entity';
import { RegisterDto, LoginDto, UpdateProfileDto } from './dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    // 检查用户是否已存在
    const existingUser = await this.userRepository.findOne({
      where: { phone: dto.phone },
    });

    if (existingUser) {
      throw new BadRequestException('手机号已注册');
    }

    // 加密密码
    const passwordHash = await bcrypt.hash(dto.password, 12);

    // 创建用户
    const user = this.userRepository.create({
      phone: dto.phone,
      passwordHash,
    });

    await this.userRepository.save(user);

    // 生成 Token
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
    // 查找用户
    const user = await this.userRepository.findOne({
      where: { phone: dto.phone },
    });

    if (!user) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    // 验证密码
    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    // 检查用户状态
    if (user.status !== 'active') {
      throw new UnauthorizedException('账户已被禁用');
    }

    // 生成 Token
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
    // 这里可以实现 Token 黑名单逻辑
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
    const payload = { sub: user.id, phone: user.phone };

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
