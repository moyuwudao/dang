-- 多模式计费系统数据库迁移脚本
-- 创建时间: 2025-06-29
-- 说明: 添加支持订阅制、资源包、按量付费的数据表

-- ============================================
-- 1. 创建套餐功能配额表
-- ============================================
CREATE TABLE IF NOT EXISTS plan_feature_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id VARCHAR(255) NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    feature_type VARCHAR(50) NOT NULL,
    quota_value INTEGER NOT NULL DEFAULT 0,
    quota_unit VARCHAR(50) NOT NULL DEFAULT 'minutes',
    multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_plan_feature_quotas_plan_id ON plan_feature_quotas(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_feature_quotas_feature_type ON plan_feature_quotas(feature_type);
CREATE UNIQUE INDEX IF NOT EXISTS idx_plan_feature_quotas_plan_feature ON plan_feature_quotas(plan_id, feature_type);

-- ============================================
-- 2. 创建用户功能使用表
-- ============================================
CREATE TABLE IF NOT EXISTS user_feature_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    feature_type VARCHAR(50) NOT NULL,
    used_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    unit VARCHAR(50) NOT NULL DEFAULT 'minutes',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_feature_usage_user_id ON user_feature_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feature_usage_subscription_id ON user_feature_usage(subscription_id);
CREATE INDEX IF NOT EXISTS idx_user_feature_usage_feature_type ON user_feature_usage(feature_type);
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_feature_usage_user_subscription_feature ON user_feature_usage(user_id, subscription_id, feature_type);

-- ============================================
-- 3. 创建Token价格配置表
-- ============================================
CREATE TABLE IF NOT EXISTS token_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(100) NOT NULL,
    model_pattern VARCHAR(255) NOT NULL,
    prompt_price_per_1k DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    completion_price_per_1k DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_token_pricing_provider ON token_pricing(provider);
CREATE INDEX IF NOT EXISTS idx_token_pricing_model_pattern ON token_pricing(model_pattern);
CREATE INDEX IF NOT EXISTS idx_token_pricing_active ON token_pricing(is_active);

-- ============================================
-- 4. 修改现有表
-- ============================================

-- 4.1 修改 subscriptions 表，添加 type 字段
ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS type VARCHAR(50) NOT NULL DEFAULT 'subscription';

-- 更新现有数据：有expiresAt的为subscription，否则为package
UPDATE subscriptions 
SET type = 'subscription' 
WHERE expires_at IS NOT NULL;

-- 4.2 修改 api_usage_logs 表，添加新字段
ALTER TABLE api_usage_logs 
ADD COLUMN IF NOT EXISTS feature_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS resource_consumed DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS unit VARCHAR(50),
ADD COLUMN IF NOT EXISTS cost_cents INTEGER;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_api_usage_logs_feature_type ON api_usage_logs(feature_type);

-- 4.3 修改 user_balances 表，添加 gift_balance_cents 字段
ALTER TABLE user_balances 
ADD COLUMN IF NOT EXISTS gift_balance_cents INTEGER NOT NULL DEFAULT 0;

-- ============================================
-- 5. 插入默认Token价格配置
-- ============================================
INSERT INTO token_pricing (provider, model_pattern, prompt_price_per_1k, completion_price_per_1k) VALUES
('openai', 'gpt-4', 30.00, 60.00),
('openai', 'gpt-4o', 5.00, 15.00),
('openai', 'gpt-3.5-turbo', 0.50, 1.50),
('anthropic', 'claude-3-opus', 15.00, 75.00),
('anthropic', 'claude-3-sonnet', 3.00, 15.00),
('anthropic', 'claude-3-haiku', 0.25, 1.25),
('gemini', 'gemini-pro', 0.50, 1.50),
('gemini', 'gemini-ultra', 10.00, 30.00),
('deepseek', 'deepseek-chat', 1.00, 2.00),
('qwen', 'qwen-turbo', 0.50, 1.50),
('qwen', 'qwen-plus', 2.00, 6.00),
('qwen', 'qwen-max', 10.00, 30.00)
ON CONFLICT DO NOTHING;

-- ============================================
-- 6. 为现有套餐创建默认功能配额
-- ============================================
-- 获取所有现有套餐
DO $$
DECLARE
    plan_record RECORD;
BEGIN
    FOR plan_record IN SELECT id, quota_type, quota_value FROM plans WHERE is_active = TRUE
    LOOP
        -- 根据套餐类型创建默认配额
        IF plan_record.quota_type = 'minutes' THEN
            INSERT INTO plan_feature_quotas (plan_id, feature_type, quota_value, quota_unit)
            VALUES 
                (plan_record.id, 'transcription', plan_record.quota_value, 'minutes'),
                (plan_record.id, 'realtime_transcription', plan_record.quota_value / 2, 'minutes')
            ON CONFLICT (plan_id, feature_type) DO NOTHING;
        END IF;
    END LOOP;
END $$;

-- ============================================
-- 7. 创建触发器自动更新 updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为新增表添加触发器
DROP TRIGGER IF EXISTS update_plan_feature_quotas_updated_at ON plan_feature_quotas;
CREATE TRIGGER update_plan_feature_quotas_updated_at
    BEFORE UPDATE ON plan_feature_quotas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_feature_usage_updated_at ON user_feature_usage;
CREATE TRIGGER update_user_feature_usage_updated_at
    BEFORE UPDATE ON user_feature_usage
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_token_pricing_updated_at ON token_pricing;
CREATE TRIGGER update_token_pricing_updated_at
    BEFORE UPDATE ON token_pricing
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. 创建视图方便查询
-- ============================================
CREATE OR REPLACE VIEW user_subscription_features AS
SELECT 
    s.id as subscription_id,
    s.user_id,
    s.plan_id,
    s.type as subscription_type,
    s.status,
    s.expires_at,
    p.name as plan_name,
    p.price_cents,
    pfq.feature_type,
    pfq.quota_value as total_quota,
    pfq.quota_unit,
    COALESCE(ufu.used_amount, 0) as used_amount,
    COALESCE(ufu.total_amount, pfq.quota_value) as current_total,
    (COALESCE(ufu.total_amount, pfq.quota_value) - COALESCE(ufu.used_amount, 0)) as remaining
FROM subscriptions s
JOIN plans p ON s.plan_id = p.id
LEFT JOIN plan_feature_quotas pfq ON p.id = pfq.plan_id
LEFT JOIN user_feature_usage ufu ON s.id = ufu.subscription_id AND pfq.feature_type = ufu.feature_type
WHERE s.status = 'active';

-- ============================================
-- 9. 添加注释
-- ============================================
COMMENT ON TABLE plan_feature_quotas IS '套餐功能配额表，定义每个套餐包含的功能及配额';
COMMENT ON TABLE user_feature_usage IS '用户功能使用表，记录用户各功能的使用情况';
COMMENT ON TABLE token_pricing IS 'Token价格配置表，定义各模型按量付费的价格';

COMMENT ON COLUMN plan_feature_quotas.feature_type IS '功能类型: transcription, realtime_transcription, text_analysis, image_recognition, ocr, ai_chat, tts';
COMMENT ON COLUMN plan_feature_quotas.quota_unit IS '配额单位: minutes, thousand_chars, images, tokens';
COMMENT ON COLUMN subscriptions.type IS '订阅类型: subscription(订阅制), package(资源包)';
