"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiConfig = void 0;
const typeorm_1 = require("typeorm");
let ApiConfig = class ApiConfig {
};
exports.ApiConfig = ApiConfig;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], ApiConfig.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], ApiConfig.prototype, "provider", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'model_pattern' }),
    __metadata("design:type", String)
], ApiConfig.prototype, "modelPattern", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'model_name', nullable: true }),
    __metadata("design:type", String)
], ApiConfig.prototype, "modelName", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'base_coefficient', type: 'decimal', precision: 10, scale: 4, default: 1.0 }),
    __metadata("design:type", Number)
], ApiConfig.prototype, "baseCoefficient", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_active', default: true }),
    __metadata("design:type", Boolean)
], ApiConfig.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], ApiConfig.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], ApiConfig.prototype, "updatedAt", void 0);
exports.ApiConfig = ApiConfig = __decorate([
    (0, typeorm_1.Entity)('api_configs')
], ApiConfig);
//# sourceMappingURL=api-config.entity.js.map