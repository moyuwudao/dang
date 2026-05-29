import { HttpService } from '@nestjs/axios';
export declare class MonitorService {
    private readonly httpService;
    private readonly agentUrl;
    private readonly agentToken;
    constructor(httpService: HttpService);
    private agentExecute;
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
        timestamp: number;
    }>;
    getServices(): Promise<any>;
    getLogs(service: string, lines?: number): Promise<{
        logs: any;
    }>;
    private readonly allowedCommands;
    private readonly forbiddenPatterns;
    private validateCommand;
    executeCommand(command: string, timeout?: number): Promise<{
        output: any;
    }>;
    private parseMemSize;
}
