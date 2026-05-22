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
    const data = await this.apiKeyService.getApiKey(req.user.sub);
    return { code: 200, message: 'success', data };
  }

  @Post('refresh')
  @UseGuards(JwtAuthGuard)
  async refreshApiKey(@Req() req) {
    const data = await this.apiKeyService.refreshApiKey(req.user.sub);
    return { code: 200, message: 'success', data };
  }

  @Get('admin/list')
  @UseGuards(JwtAuthGuard)
  async getApiKeys() {
    const data = await this.apiKeyService.getApiKeys();
    return { code: 200, message: 'success', data };
  }

  @Post('admin/create')
  @UseGuards(JwtAuthGuard)
  async createApiKey(@Body() dto: CreateApiKeyDto) {
    const data = await this.apiKeyService.createApiKey(dto);
    return { code: 200, message: 'success', data };
  }

  @Delete('admin/:id')
  @UseGuards(JwtAuthGuard)
  async deleteApiKey(@Param('id') id: string) {
    await this.apiKeyService.deleteApiKey(id);
    return { code: 200, message: 'success', data: null };
  }
}
