#!/bin/bash
cd /opt/changji-cloud/api

TOKEN=$(node -e "
const jwt = require('jsonwebtoken');
const secret = 'changji_jwt_secret_change_me';
const token = jwt.sign({ sub: '8ea73580-c6f3-4fe0-81db-a5e2febfbe14', phone: '13800138001' }, secret, { expiresIn: '1h' });
console.log(token);
")

echo "=== Subscription API (with model details) ==="
curl -s http://localhost:3000/api/v1/subscription \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d, indent=2, ensure_ascii=False))" 2>/dev/null
