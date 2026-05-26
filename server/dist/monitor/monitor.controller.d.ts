import { MonitorService } from './monitor.service';
export declare class MonitorController {
    private readonly monitorService;
    constructor(monitorService: MonitorService);
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
            timestamp: any;
        };
    }>;
    getServices(): Promise<{
        code: number;
        message: string;
        data: {
            name: string;
            status: any;
            active: boolean;
        }[];
    }>;
    getLogs(body: {
        service: string;
        lines?: number;
    }): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    executeCommand(body: {
        command: string;
        timeout?: number;
    }): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
}
