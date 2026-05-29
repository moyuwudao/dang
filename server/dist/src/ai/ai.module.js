"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiModule = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("@nestjs/axios");
const jwt_1 = require("@nestjs/jwt");
const typeorm_1 = require("@nestjs/typeorm");
const ai_controller_1 = require("./ai.controller");
const ai_service_1 = require("./ai.service");
const ai_router_service_1 = require("./ai-router.service");
const api_key_module_1 = require("../api-key/api-key.module");
const subscription_module_1 = require("../subscription/subscription.module");
const redis_module_1 = require("../redis/redis.module");
const api_usage_log_entity_1 = require("../subscription/entities/api-usage-log.entity");
const plan_api_policy_entity_1 = require("../subscription/entities/plan-api-policy.entity");
const api_key_entity_1 = require("../api-key/entities/api-key.entity");
let AiModule = class AiModule {
};
exports.AiModule = AiModule;
exports.AiModule = AiModule = __decorate([
    (0, common_1.Module)({
        imports: [
            axios_1.HttpModule,
            jwt_1.JwtModule.register({
                secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
                signOptions: { expiresIn: '15m' },
            }),
            api_key_module_1.ApiKeyModule,
            subscription_module_1.SubscriptionModule,
            redis_module_1.RedisModule,
            typeorm_1.TypeOrmModule.forFeature([api_usage_log_entity_1.ApiUsageLog, plan_api_policy_entity_1.PlanApiPolicy, api_key_entity_1.ApiKey]),
        ],
        controllers: [ai_controller_1.AiController],
        providers: [ai_service_1.AiService, ai_router_service_1.AiRouterService],
        exports: [ai_router_service_1.AiRouterService],
    })
], AiModule);
//# sourceMappingURL=ai.module.js.map