import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { MonitorController } from './monitor.controller';
import { MonitorService } from './monitor.service';

@Module({
  imports: [HttpModule],
  controllers: [MonitorController],
  providers: [MonitorService],
})
export class MonitorModule {}
