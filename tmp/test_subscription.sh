#!/bin/bash
TOKEN=$(curl -s --max-time 10 -X POST http://101.133.238.249/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138001","password":"ChangJi@2026#Admin!"}' | \
  grep -o '"accessToken":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "Token: $TOKEN"
echo ""
echo "=== Subscription Response ==="
curl -s --max-time 10 http://101.133.238.249/api/v1/subscription \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool 2>/dev/null || cat
