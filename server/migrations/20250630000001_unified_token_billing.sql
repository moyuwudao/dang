-- ============================================================
-- 统一Token计费系统迁移脚本
-- 创建时间: 2026-05-30
-- 说明: 
-- 1. 创建新的Token定价表（支持所有功能类型）
-- 2. 创建用户Token余额表
-- 3. 扩展api_usage_logs表
-- 4. 初始化定价数据
-- ============================================================

-- 第一步：创建新的Token定价表
DROP TABLE IF EXISTS token_pricing_new;
CREATE TABLE token_pricing_new (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_type VARCHAR(50) NOT NULL,
  provider VARCHAR(50) NOT NULL,
  model_pattern VARCHAR(100) NOT NULL,
  model_name VARCHAR(100),
  conversion_rate DECIMAL(10,4) NOT NULL DEFAULT 1.0,
  price_per_token DECIMAL(10,6) NOT NULL DEFAULT 0.002,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建唯一索引
CREATE UNIQUE INDEX idx_token_pricing_unique 
ON token_pricing_new(feature_type, provider, model_pattern);

-- 第二步：创建用户Token余额表
DROP TABLE IF EXISTS user_token_balances;
CREATE TABLE user_token_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(100) NOT NULL UNIQUE,
  balance_tokens DECIMAL(15,4) NOT NULL DEFAULT 0,
  total_consumed_tokens DECIMAL(15,4) NOT NULL DEFAULT 0,
  free_tokens_remaining DECIMAL(15,4) NOT NULL DEFAULT 500,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 第三步：扩展api_usage_logs表
ALTER TABLE api_usage_logs 
  ADD COLUMN IF NOT EXISTS token_consumed DECIMAL(15,4),
  ADD COLUMN IF NOT EXISTS cost_yuan DECIMAL(10,4),
  ADD COLUMN IF NOT EXISTS conversion_rate DECIMAL(10,4),
  ADD COLUMN IF NOT EXISTS feature_type VARCHAR(50);

-- 第四步：初始化AI对话定价数据（基于实际API Key）
INSERT INTO token_pricing_new (feature_type, provider, model_pattern, model_name, conversion_rate, price_per_token) VALUES
-- qwen 系列（基准系数1.0）
('ai_chat', 'qwen', 'qwen3.6-flash', 'Qwen 3.6 Flash', 1.0, 0.002),
('ai_chat', 'qwen', 'qwen3.6-plus', 'Qwen 3.6 Plus', 1.5, 0.002),
('ai_chat', 'qwen', 'qwen3.6-max-preview', 'Qwen 3.6 Max Preview', 4.5, 0.002),

-- deepseek 系列
('ai_chat', 'deepseek', 'deepseek-v4-flash', 'DeepSeek V4 Flash', 0.75, 0.002),
('ai_chat', 'deepseek', 'deepseek-v4-pro', 'DeepSeek V4 Pro', 9.0, 0.002);

-- 第五步：初始化其他功能类型定价（预留）
-- 语音转写：1分钟 = 1200 Token（系数1200）
INSERT INTO token_pricing_new (feature_type, provider, model_pattern, model_name, conversion_rate, price_per_token) VALUES
('transcription', 'qwen', 'qwen-audio', 'Qwen Audio', 1200.0, 0.002),
('transcription', 'deepseek', 'deepseek-audio', 'DeepSeek Audio', 1200.0, 0.002);

-- 图片识别：1张 = 2000 Token（系数2000）
INSERT INTO token_pricing_new (feature_type, provider, model_pattern, model_name, conversion_rate, price_per_token) VALUES
('image', 'qwen', 'qwen-vl', 'Qwen VL', 2000.0, 0.002),
('image', 'deepseek', 'deepseek-vl', 'DeepSeek VL', 2000.0, 0.002);

-- OCR：1张 = 800 Token（系数800）
INSERT INTO token_pricing_new (feature_type, provider, model_pattern, model_name, conversion_rate, price_per_token) VALUES
('ocr', 'qwen', 'qwen-ocr', 'Qwen OCR', 800.0, 0.002);

-- 语音合成：1字符 = 0.5 Token（系数0.5）
INSERT INTO token_pricing_new (feature_type, provider, model_pattern, model_name, conversion_rate, price_per_token) VALUES
('tts', 'qwen', 'qwen-tts', 'Qwen TTS', 0.5, 0.002);

-- 第六步：迁移旧数据（如果有）
-- 将旧的用户余额转换为Token余额（简化处理：1配额 = 100 Token）
INSERT INTO user_token_balances (user_id, balance_tokens, total_consumed_tokens, free_tokens_remaining)
SELECT 
  user_id,
  COALESCE(balance_cents / 0.002, 0) as balance_tokens,
  COALESCE(total_consumed_tokens, 0) as total_consumed_tokens,
  500 as free_tokens_remaining
FROM user_balances
ON CONFLICT (user_id) DO NOTHING;

-- 第七步：验证数据
SELECT 'Token定价配置' as section, COUNT(*) as count FROM token_pricing_new
UNION ALL
SELECT '用户Token余额', COUNT(*) FROM user_token_balances;

-- 显示定价详情
SELECT feature_type, provider, model_pattern, model_name, conversion_rate, price_per_token
FROM token_pricing_new
ORDER BY feature_type, provider, model_pattern;
