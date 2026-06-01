import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { RegisterDto, LoginDto, UpdateProfileDto, SmsLoginDto } from './dto';
import { SubscriptionService } from '../subscription/subscription.service';
import { SmsService } from './sms.service';
export declare class AuthService {
    private userRepository;
    private jwtService;
    private subscriptionService;
    private smsService;
    private redisClient;
    constructor(userRepository: Repository<User>, jwtService: JwtService, subscriptionService: SubscriptionService, smsService: SmsService);
    register(dto: RegisterDto): Promise<{
        code: number;
        message: string;
        data: {
            accessToken: string;
            refreshToken: string;
            user: any;
        };
    }>;
    login(dto: LoginDto): Promise<{
        code: number;
        message: string;
        data: {
            accessToken: string;
            refreshToken: string;
            user: any;
        };
    }>;
    sendSmsCode(phone: string): Promise<{
        code: number;
        message: string;
        data: {
            needCaptcha: boolean;
        };
    }>;
    smsLogin(dto: SmsLoginDto): Promise<{
        code: number;
        message: string;
        data: {
            accessToken: string;
            refreshToken: string;
            user: any;
        };
    }>;
    refresh(refreshToken: string): Promise<{
        code: number;
        message: string;
        data: {
            accessToken: string;
            refreshToken: string;
        };
    }>;
    logout(userId: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getProfile(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            user: any;
        };
    }>;
    updateProfile(userId: string, dto: UpdateProfileDto): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    private generateTokens;
    private sanitizeUser;
}
