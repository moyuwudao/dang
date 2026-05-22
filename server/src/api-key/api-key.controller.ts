import { Controller, Get, Post, Delete, UseGuards, Req, Body, Param } from '@nestjs/common';
import { ApiKeyService } from './api-key.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateApiKeyDto } from './dto';

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

  @Get('admin/list')
  @UseGuards(JwtAuthGuard)
  async getApiKeys() {
    return this.apiKeyService.getApiKeys();
  }

  @Post('admin/create')
  @UseGuards(JwtAuthGuard)
  async createApiKey(@Body() dto: CreateApiKeyDto) {
    return this.apiKeyService.createApiKey(dto);
  }

  @Delete('admin/:id')
  @UseGuards(JwtAuthGuard)
  async deleteApiKey(@Param('id') id: string) {
    return this.apiKeyService.deleteApiKey(id);
  }
}
