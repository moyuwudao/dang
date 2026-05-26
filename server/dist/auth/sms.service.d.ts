export declare class SmsService {
    private readonly accessKeyId;
    private readonly accessKeySecret;
    private readonly signName;
    private readonly templateCode;
    constructor();
    private generateSignature;
    private sendRequest;
    sendVerificationCode(phone: string): Promise<boolean>;
}
