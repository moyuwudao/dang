import { Controller, Post, Get, UseGuards, UseInterceptors, Body, Req, Query, UploadedFile } from '@nestjs/common';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RedisRateLimitInterceptor } from '../common/interceptors/redis-rate-limit.interceptor';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('chat')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(RedisRateLimitInterceptor)
  async chat(@Req() req, @Body() body: {
    messages: Array<{ role: string; content: string }>;
    provider?: string;
    model?: string;
    stream?: boolean;
  }) {
    return this.aiService.chat(req.user.sub, body);
  }

  @Post('transcribe')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    RedisRateLimitInterceptor,
    FileInterceptor('audio', {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, callback) => {
          const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          const ext = extname(file.originalname);
          callback(null, `audio-${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (req, file, callback) => {
        const allowedExtensions = ['.wav', '.mp3', '.m4a', '.ogg'];
        const ext = extname(file.originalname).toLowerCase();
        if (allowedExtensions.includes(ext)) {
          callback(null, true);
        } else {
          callback(new Error('不支持的音频格式'), false);
        }
      },
      limits: {
        fileSize: 50 * 1024 * 1024, // 50MB
      },
    }),
  )
  async transcribe(@Req() req, @UploadedFile() file: Express.Multer.File, @Body() body: {
    provider?: string;
    language?: string;
  }) {
    return this.aiService.transcribe(req.user.sub, {
      audioPath: file.path,
      provider: body.provider,
      language: body.language,
    });
  }

  @Get('usage')
  @UseGuards(JwtAuthGuard)
  async getUsage(
    @Req() req,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.aiService.getUsage(req.user.sub, startDate, endDate);
  }
}
