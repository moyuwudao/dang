ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS balance_quota INT DEFAULT 0;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS api_policy_type VARCHAR(20) DEFAULT 'all';
ALTER TABLE plans ADD COLUMN IF NOT EXISTS type VARCHAR(20) DEFAULT 'subscription';
SELECT column_name FROM information_schema.columns WHERE table_name IN ('plans', 'subscriptions') ORDER BY table_name, ordinal_position;
