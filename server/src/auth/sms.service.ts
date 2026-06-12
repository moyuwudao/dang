import { Injectable, BadRequestException, InternalServerErrorException, Logger } from '@nestjs/common';
import axios from 'axios';
import * as crypto from 'crypto';

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private readonly accessKeyId: string;
  private readonly accessKeySecret: string;
  private readonly signName: string;
  private readonly templateCode: string;

  constructor() {
    this.accessKeyId = process.env.SMS_ACCESS_KEY_ID || '';
    this.accessKeySecret = process.env.SMS_ACCESS_KEY_SECRET || '';
    this.signName = process.env.SMS_SIGN_NAME || '';
    this.templateCode = process.env.SMS_TEMPLATE_CODE || '';
  }

  /**
   * 阿里云专用 percentEncode：按 RFC3986 编码，~ 不编码，* 编码为 %2A
   */
  private percentEncode(value: string): string {
    return encodeURIComponent(value)
      .replace(/!/g, '%21')
      .replace(/'/g, '%27')
      .replace(/\(/g, '%28')
      .replace(/\)/g, '%29')
      .replace(/\*/g, '%2A');
  }

  private generateSignature(params: Record<string, string>): string {
    // 1. 构造规范化查询字符串：参数按键名升序排列
    const sortedKeys = Object.keys(params).sort();
    const canonicalQueryString = sortedKeys
      .map(key => `${this.percentEncode(key)}=${this.percentEncode(params[key])}`)
      .join('&');

    // 2. 构造待签名字符串
    const stringToSign = `GET&${this.percentEncode('/')}&${this.percentEncode(canonicalQueryString)}`;

    // 3. 计算 HMAC-SHA1 签名
    const hmac = crypto.createHmac('sha1', `${this.accessKeySecret}&`);
    return hmac.update(stringToSign).digest('base64');
  }

  private async sendRequest(params: Record<string, string>): Promise<any> {
    const signature = this.generateSignature(params);

    // Signature 需要单独 URL 编码（Base64 结果可能含 + / =）
    const query = new URLSearchParams();
    query.append('Signature', signature);
    for (const [key, value] of Object.entries(params)) {
      query.append(key, value);
    }

    const url = `https://dysmsapi.aliyuncs.com/?${query.toString()}`;

    try {
      const response = await axios.get(url, { timeout: 10000 });
      return response.data;
    } catch (error: any) {
      this.logger.error(`SMS request failed: ${error?.message || String(error)}`);
      if (error.response?.data) {
        this.logger.error(`SMS error response: ${JSON.stringify(error.response.data)}`);
      }
      throw new InternalServerErrorException('短信发送失败');
    }
  }

  /**
   * 发送验证码短信
   * @param phone 手机号
   * @param code 验证码（调用方传入，确保与 Redis 中存储的一致）
   */
  async sendVerificationCode(phone: string, code: string): Promise<boolean> {
    if (!this.accessKeyId || !this.accessKeySecret || !this.signName || !this.templateCode) {
      throw new BadRequestException('短信服务未配置');
    }

    const params: Record<string, string> = {
      AccessKeyId: this.accessKeyId,
      Action: 'SendSms',
      Format: 'JSON',
      PhoneNumbers: phone,
      RegionId: 'cn-hangzhou',
      SignName: this.signName,
      SignatureMethod: 'HMAC-SHA1',
      SignatureNonce: Date.now().toString() + Math.random().toString(36).substring(2, 9),
      SignatureVersion: '1.0',
      TemplateCode: this.templateCode,
      TemplateParam: JSON.stringify({ code }),
      Timestamp: new Date().toISOString(),
      Version: '2017-05-25',
    };

    const result = await this.sendRequest(params);
    this.logger.log(`SMS send result: ${JSON.stringify(result)}`);

    if (result.Code === 'OK') {
      return true;
    } else {
      throw new BadRequestException(result.Message || '短信发送失败');
    }
  }
}