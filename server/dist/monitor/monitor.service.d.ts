import { HttpService } from '@nestjs/axios';
export declare class MonitorService {
    private readonly httpService;
    private readonly agentUrl;
    private readonly agentToken;
    constructor(httpService: HttpService);
    private agentRequest;
    getSystemInfo(): Promise<{
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
    }>;
    getServices(): Promise<{
        name: string;
        status: any;
        active: boolean;
    }[]>;
    getLogs(service: string, lines?: number): Promise<any>;
    executeCommand(command: string, timeout?: number): Promise<any>;
    private parseSize;
}
