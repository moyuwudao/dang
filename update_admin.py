import psycopg2
import uuid

conn = psycopg2.connect(
    dbname='appdb',
    user='appuser',
    password='AppUser123456',
    host='localhost'
)
cur = conn.cursor()

# 更新现有用户为管理员，设置新密码
cur.execute("""
    UPDATE users 
    SET "passwordHash" = %s, 
        role = %s, 
        nickname = %s,
        "updatedAt" = NOW()
    WHERE phone = %s
""", ('$2a$12$Ebfm43Vs3YxuFzwPKx9b4eA0dT5n8cCiHu5JmKKmiP2yiuAVPtHSO', 'admin', '超级管理员', '13800138001'))

conn.commit()
print('管理员账户更新成功!')
print('用户名: 13800138001')
print('密码: Admin@2026#Secure!')

cur.close()
conn.close()