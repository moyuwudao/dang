import { MonitorService } from './monitor.service';
import { MetricsService, MetricsData } from './metrics.service';
export declare class MonitorController {
    private readonly monitorService;
    private readonly metricsService;
    constructor(monitorService: MonitorService, metricsService: MetricsService);
    getSystemInfo(): Promise<{
        code: number;
        message: string;
        data: {
            hostname: string;
            platform: string;
            uptime: number;
            cpu: {
                usage: number;
                cores: number;
                model: string;
            };
            memory: {
                total: number;
                used: number;
                free: number;
                usagePercent: number;
            };
            disk: {
                total: number;
                used: number;
                free: number;
                usagePercent: number;
            };
            load: number[];
            timestamp: number;
        };
    }>;
    getServices(): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getLogs(body: {
        service: string;
        lines?: number;
    }): Promise<{
        code: number;
        message: string;
        data: {
            logs: any;
        };
    }>;
    executeCommand(body: {
        command: string;
        timeout?: number;
    }): Promise<{
        code: number;
        message: string;
        data: {
            output: any;
        };
    }>;
    getRealtimeMetrics(): Promise<{
        code: number;
        message: string;
        data: MetricsData;
    }>;
    getDailyMetrics(date?: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getTrendData(days?: string): Promise<{
        code: number;
        message: string;
        data: any[];
    }>;
}
