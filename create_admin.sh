#!/bin/bash

# 创建管理员账户
PASSWORD="Admin@2026#Secure!"
PHONE="13900139000"

# 使用 bcrypt 生成密码哈希
HASH=$(cd /home/admin/dang/server && node -e "const bcrypt=require('bcryptjs');bcrypt.hash('$PASSWORD',12).then(h=>console.log(h));")

echo "生成的密码哈希: $HASH"

# 插入数据库
sudo -u postgres psql -d appdb << EOF
INSERT INTO users (id, phone, "passwordHash", nickname, status, role, "createdAt", "updatedAt")
VALUES (gen_random_uuid(), '$PHONE', '$HASH', '超级管理员', 'active', 'admin', NOW(), NOW());
EOF

echo "管理员账户创建完成!"
echo "用户名: $PHONE"
echo "密码: $PASSWORD"