import Redis from 'ioredis';
export declare class RedisService {
    private readonly redis;
    constructor(redis: Redis);
    get(key: string): Promise<string | null>;
    set(key: string, value: string, ttl?: number): Promise<void>;
    del(key: string): Promise<void>;
    increment(key: string, amount?: number): Promise<number>;
    decrement(key: string, amount?: number): Promise<number>;
    expire(key: string, seconds: number): Promise<void>;
    ttl(key: string): Promise<number>;
    exists(key: string): Promise<boolean>;
    rateLimit(key: string, limit: number, windowSeconds: number): Promise<{
        allowed: boolean;
        remaining: number;
        resetTime: number;
    }>;
}
