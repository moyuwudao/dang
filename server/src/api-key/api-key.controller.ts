import { Controller, Get, Post, UseGuards, Req } from '@nestjs/common';
import { ApiKeyService } from './api-key.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('api-key')
export class ApiKeyController {
  constructor(private readonly apiKeyService: ApiKeyService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async getApiKey(@Req() req) {
    return this.apiKeyService.getApiKey(req.user.sub);
  }

  @Post('refresh')
  @UseGuards(JwtAuthGuard)
  async refreshApiKey(@Req() req) {
    return this.apiKeyService.refreshApiKey(req.user.sub);
  }
}
