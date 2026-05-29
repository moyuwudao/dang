#!/bin/bash
echo "=== Health Check ==="
curl -s http://127.0.0.1:3000/api/v1/health
echo ""
echo ""
echo "=== Admin Login ==="
curl -s -X POST http://127.0.0.1:3000/api/v1/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138001","password":"ChangJi@2026#Admin!"}'
echo ""
