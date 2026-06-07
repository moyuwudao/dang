import { Controller, Post, Get, UseGuards, UseInterceptors, Body, Req, Query } from '@nestjs/common';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RedisRateLimitInterceptor } from '../common/interceptors/redis-rate-limit.interceptor';

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
  @UseInterceptors(RedisRateLimitInterceptor)
  async transcribe(@Req() req, @Body() body: {
    audioUrl: string;
    provider?: string;
    language?: string;
  }) {
    return this.aiService.transcribe(req.user.sub, body);
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

  @Post('report-usage')
  @UseGuards(JwtAuthGuard)
  async reportUsage(@Req() req, @Body() body: {
    provider: string;
    model: string;
    promptTokens: number;
    completionTokens: number;
    featureType?: string;
  }) {
    return this.aiService.reportUsage(req.user.sub, body);
  }
}
