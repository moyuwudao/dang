"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const core_1 = require("@nestjs/core");
const auth_module_1 = require("./auth/auth.module");
const subscription_module_1 = require("./subscription/subscription.module");
const api_key_module_1 = require("./api-key/api-key.module");
const admin_module_1 = require("./admin/admin.module");
const schedule_1 = require("@nestjs/schedule");
const monitor_module_1 = require("./monitor/monitor.module");
const redis_module_1 = require("./redis/redis.module");
const ai_module_1 = require("./ai/ai.module");
const payment_module_1 = require("./payment/payment.module");
const plan_module_1 = require("./plan/plan.module");
const jwt_auth_guard_1 = require("./auth/guards/jwt-auth.guard");
const response_interceptor_1 = require("./common/interceptors/response.interceptor");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                envFilePath: '.env',
            }),
            typeorm_1.TypeOrmModule.forRoot({
                type: 'postgres',
                host: process.env.DB_HOST || 'localhost',
                port: parseInt(process.env.DB_PORT, 10) || 5432,
                username: process.env.DB_USER || 'appuser',
                password: process.env.DB_PASSWORD || 'AppUser123456',
                database: process.env.DB_NAME || 'appdb',
                entities: [__dirname + '/**/*.entity{.ts,.js}'],
                synchronize: false,
                logging: false,
            }),
            schedule_1.ScheduleModule.forRoot(),
            auth_module_1.AuthModule,
            subscription_module_1.SubscriptionModule,
            api_key_module_1.ApiKeyModule,
            admin_module_1.AdminModule,
            monitor_module_1.MonitorModule,
            redis_module_1.RedisModule,
            ai_module_1.AiModule,
            payment_module_1.PaymentModule,
            plan_module_1.PlanModule,
        ],
        providers: [
            {
                provide: core_1.APP_GUARD,
                useClass: jwt_auth_guard_1.JwtAuthGuard,
            },
            {
                provide: core_1.APP_INTERCEPTOR,
                useClass: response_interceptor_1.ResponseInterceptor,
            },
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map