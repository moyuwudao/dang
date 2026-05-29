CREATE TABLE IF NOT EXISTS plan_default_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id VARCHAR NOT NULL,
    function_type VARCHAR NOT NULL,
    model_pattern VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_plan_default_configs_plan_id ON plan_default_configs(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_default_configs_function_type ON plan_default_configs(function_type);
