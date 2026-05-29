#!/bin/bash
echo "=== Test Auth Login ==="
curl -s -X POST http://127.0.0.1:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138001","password":"ChangJi@2026#Admin!"}'
echo ""
echo ""
echo "=== Test Subscription ==="
curl -s http://127.0.0.1:3000/api/v1/subscription
echo ""
