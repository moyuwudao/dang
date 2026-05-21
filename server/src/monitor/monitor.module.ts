import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { MonitorController } from './monitor.controller';
import { MonitorService } from './monitor.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [HttpModule, AuthModule],
  controllers: [MonitorController],
  providers: [MonitorService],
})
export class MonitorModule {}
