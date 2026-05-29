"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiKeyModule = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const typeorm_1 = require("@nestjs/typeorm");
const axios_1 = require("@nestjs/axios");
const api_key_controller_1 = require("./api-key.controller");
const api_key_service_1 = require("./api-key.service");
const api_key_health_service_1 = require("./api-key-health.service");
const api_key_entity_1 = require("./entities/api-key.entity");
const user_api_key_entity_1 = require("./entities/user-api-key.entity");
const rate_limit_interceptor_1 = require("./interceptors/rate-limit.interceptor");
let ApiKeyModule = class ApiKeyModule {
};
exports.ApiKeyModule = ApiKeyModule;
exports.ApiKeyModule = ApiKeyModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([api_key_entity_1.ApiKey, user_api_key_entity_1.UserApiKey]),
            axios_1.HttpModule,
            jwt_1.JwtModule.register({
                secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
                signOptions: { expiresIn: '15m' },
            }),
        ],
        controllers: [api_key_controller_1.ApiKeyController],
        providers: [api_key_service_1.ApiKeyService, api_key_health_service_1.ApiKeyHealthService, rate_limit_interceptor_1.RateLimitInterceptor],
        exports: [api_key_service_1.ApiKeyService, api_key_health_service_1.ApiKeyHealthService],
    })
], ApiKeyModule);
//# sourceMappingURL=api-key.module.js.map