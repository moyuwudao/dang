-- 畅记云服务 - 数据库初始化脚本

-- 插入套餐数据
INSERT INTO plans (id, name, description, price_cents, duration_days, quota_type, quota_value, is_active)
VALUES 
  ('free', '免费版', '免费体验套餐，适合个人使用', 0, 30, 'minutes', 30, true),
  ('basic', '基础版', '基础功能套餐，适合轻度用户', 9900, 30, 'minutes', 300, true),
  ('pro', '专业版', '专业功能套餐，适合专业用户', 29900, 30, 'minutes', 1000, true),
  ('enterprise', '企业版', '企业级套餐，无限使用', 99900, 30, 'unlimited', 0, true)
ON CONFLICT (id) DO NOTHING;

-- 提示信息
SELECT '套餐数据初始化完成' AS message;
