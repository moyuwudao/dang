import { Injectable, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import axios from 'axios';
import * as crypto from 'crypto';

@Injectable()
export class SmsService {
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

  private generateSignature(params: Record<string, string>): string {
    const sortedParams = Object.keys(params)
      .sort()
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
      .join('&');
    
    const stringToSign = `GET&%2F&${encodeURIComponent(sortedParams)}`;
    const hmac = crypto.createHmac('sha1', `${this.accessKeySecret}&`);
    return hmac.update(stringToSign).digest('base64');
  }

  private async sendRequest(params: Record<string, string>): Promise<any> {
    const signature = this.generateSignature(params);
    const url = `https://dysmsapi.aliyuncs.com/?Signature=${signature}&${new URLSearchParams(params).toString()}`;

    try {
      const response = await axios.get(url);
      return response.data;
    } catch (error) {
      throw new InternalServerErrorException('短信发送失败');
    }
  }

  async sendVerificationCode(phone: string): Promise<boolean> {
    if (!this.accessKeyId || !this.accessKeySecret || !this.signName || !this.templateCode) {
      throw new BadRequestException('短信服务未配置');
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    const params: Record<string, string> = {
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
    } else {
      throw new BadRequestException(result.Message || '短信发送失败');
    }
  }
}