import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, RefreshTokenDto, UpdateProfileDto, SendSmsCodeDto, SmsLoginDto } from './dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
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
    refresh(dto: RefreshTokenDto): Promise<{
        code: number;
        message: string;
        data: {
            accessToken: string;
            refreshToken: string;
        };
    }>;
    logout(req: any): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getProfile(req: any): Promise<{
        code: number;
        message: string;
        data: {
            user: any;
        };
    }>;
    getProfileByPath(req: any): Promise<{
        code: number;
        message: string;
        data: {
            user: any;
        };
    }>;
    updateProfile(req: any, dto: UpdateProfileDto): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getCaptcha(): Promise<{
        code: number;
        message: string;
        data: {
            captchaId: string;
            captchaUrl: string;
            needCaptcha: boolean;
        };
    }>;
    sendSmsCode(dto: SendSmsCodeDto): Promise<{
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
}
