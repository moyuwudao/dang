"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SmsService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("axios");
const crypto = require("crypto");
let SmsService = class SmsService {
    constructor() {
        this.accessKeyId = process.env.SMS_ACCESS_KEY_ID || '';
        this.accessKeySecret = process.env.SMS_ACCESS_KEY_SECRET || '';
        this.signName = process.env.SMS_SIGN_NAME || '';
        this.templateCode = process.env.SMS_TEMPLATE_CODE || '';
    }
    generateSignature(params) {
        const sortedParams = Object.keys(params)
            .sort()
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
            .join('&');
        const stringToSign = `GET&%2F&${encodeURIComponent(sortedParams)}`;
        const hmac = crypto.createHmac('sha1', `${this.accessKeySecret}&`);
        return hmac.update(stringToSign).digest('base64');
    }
    async sendRequest(params) {
        const signature = this.generateSignature(params);
        const url = `https://dysmsapi.aliyuncs.com/?Signature=${signature}&${new URLSearchParams(params).toString()}`;
        try {
            const response = await axios_1.default.get(url);
            return response.data;
        }
        catch (error) {
            throw new common_1.InternalServerErrorException('短信发送失败');
        }
    }
    async sendVerificationCode(phone) {
        if (!this.accessKeyId || !this.accessKeySecret || !this.signName || !this.templateCode) {
            throw new common_1.BadRequestException('短信服务未配置');
        }
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const params = {
            AccessKeyId: this.accessKeyId,
            Action: 'SendSms',
            Format: 'JSON',
            PhoneNumbers: phone,
            RegionId: 'cn-hangzhou',
            SignName: this.signName,
            SignatureMethod: 'HMAC-SHA1',
            SignatureNonce: Date.now().toString() + Math.random().toString(36).substr(2, 9),
            SignatureVersion: '1.0',
            TemplateCode: this.templateCode,
            TemplateParam: JSON.stringify({ code }),
            Timestamp: new Date().toISOString(),
            Version: '2017-05-25',
        };
        const result = await this.sendRequest(params);
        if (result.Code === 'OK') {
            return true;
        }
        else {
            throw new common_1.BadRequestException(result.Message || '短信发送失败');
        }
    }
};
exports.SmsService = SmsService;
exports.SmsService = SmsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], SmsService);
//# sourceMappingURL=sms.service.js.map