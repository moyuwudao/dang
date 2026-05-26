import { Controller, Get, Post, Put, Delete, UseGuards, UseInterceptors, Req, Body, Param } from '@nestjs/common';
import { ApiKeyService } from './api-key.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RateLimitInterceptor } from './interceptors/rate-limit.interceptor';
import { AuditInterceptor } from '../admin/interceptors/audit.interceptor';
import { CreateApiKeyDto } from './dto';

@Controller('api-key')
export class ApiKeyController {
  constructor(private readonly apiKeyService: ApiKeyService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(RateLimitInterceptor)
  async getApiKey(@Req() req) {
    return this.apiKeyService.getApiKey(req.user.sub);
  }

  @Post('refresh')
  @UseGuards(JwtAuthGuard)
  async refreshApiKey(@Req() req) {
    return this.apiKeyService.refreshApiKey(req.user.sub);
  }

  // 管理员接口（需要管理员权限）
  @Get('admin/list')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async getApiKeys() {
    return this.apiKeyService.getApiKeys();
  }

  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async getApiKeyStats() {
    return this.apiKeyService.getApiKeyStats();
  }

  @Get('admin/:id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async getApiKeyById(@Param('id') id: string) {
    return this.apiKeyService.getApiKeyById(id);
  }

  @Post('admin/create')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async createApiKey(@Body() dto: CreateApiKeyDto) {
    return this.apiKeyService.createApiKey(dto);
  }

  @Post('admin/batch')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async batchCreateApiKeys(@Body() dtos: CreateApiKeyDto[]) {
    const results = [];
    for (const dto of dtos) {
      try {
        const result = await this.apiKeyService.createApiKey(dto);
        results.push({ success: true, data: result.data });
      } catch (error) {
        results.push({ success: false, error: error.message, name: dto.name });
      }
    }
    return {
      code: 200,
      message: '批量创建完成',
      data: results,
    };
  }

  @Put('admin/:id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async updateApiKey(@Param('id') id: string, @Body() dto: Partial<CreateApiKeyDto>) {
    return this.apiKeyService.updateApiKey(id, dto);
  }

  @Delete('admin/:id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async deleteApiKey(@Param('id') id: string) {
    return this.apiKeyService.deleteApiKey(id);
  }

  @Post('admin/:id/test')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(AuditInterceptor)
  async testApiKey(@Param('id') id: string) {
    return this.apiKeyService.testApiKey(id);
  }
}
