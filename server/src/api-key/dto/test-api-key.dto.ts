import { IsIn, IsOptional, IsString } from 'class-validator';

export type TestableFeature =
  | 'textAnalysis'
  | 'speechTranscribe'
  | 'speechRealtime'
  | 'speechOffline'
  | 'imageRecognition';

export class TestApiKeyDto {
  // 要测试的功能：5 种具体功能 + 'connectivity'（仅鉴权/连通性检查）
  // 不传时默认为 'connectivity'，所以标为可选
  @IsIn([
    'textAnalysis',
    'speechTranscribe',
    'speechRealtime',
    'speechOffline',
    'imageRecognition',
    'connectivity',
  ])
  @IsOptional()
  feature?: TestableFeature | 'connectivity';

  // 可选：测试用文本（默认 "ping"）
  @IsString()
  @IsOptional()
  testText?: string;

  // 可选：测试用音频 URL（默认一段 base64 静音）
  @IsString()
  @IsOptional()
  testAudioUrl?: string;

  // 可选：测试用图片 URL
  @IsString()
  @IsOptional()
  testImageUrl?: string;
}
