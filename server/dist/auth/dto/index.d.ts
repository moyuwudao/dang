export declare class RegisterDto {
    phone: string;
    password: string;
    smsCode: string;
}
export declare class LoginDto {
    phone: string;
    password: string;
}
export declare class RefreshTokenDto {
    refreshToken: string;
}
export declare class UpdateProfileDto {
    nickname?: string;
    avatarUrl?: string;
}
export declare class SendSmsCodeDto {
    phone: string;
    captcha?: string;
}
export declare class SmsLoginDto {
    phone: string;
    smsCode: string;
}
