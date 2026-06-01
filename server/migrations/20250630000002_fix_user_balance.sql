-- 修复用户余额表结构
-- 检查user_balances表结构
\d user_balances

-- 如果user_balances表不存在或结构不同，跳过迁移
DO $$
BEGIN
    -- 检查user_balances表是否存在
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_balances') THEN
        -- 检查是否有user_id列
        IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_balances' AND column_name = 'user_id') THEN
            -- 迁移旧数据
            INSERT INTO user_token_balances (user_id, balance_tokens, total_consumed_tokens, free_tokens_remaining)
            SELECT 
                user_id,
                COALESCE(balance_cents / 0.002, 0) as balance_tokens,
                COALESCE(total_consumed_tokens, 0) as total_consumed_tokens,
                500 as free_tokens_remaining
            FROM user_balances
            ON CONFLICT (user_id) DO NOTHING;
        ELSE
            RAISE NOTICE 'user_balances表没有user_id列，跳过数据迁移';
        END IF;
    ELSE
        RAISE NOTICE 'user_balances表不存在，跳过数据迁移';
    END IF;
END $$;

-- 验证数据
SELECT '用户Token余额' as section, COUNT(*) as count FROM user_token_balances;
