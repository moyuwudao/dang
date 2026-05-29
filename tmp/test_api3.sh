#!/bin/bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4ZWE3MzU4MC1jNmYzLTRmZTAtODFkYi1hNWUyZmViZmJlMTQiLCJwaG9uZSI6IjEzODAwMTM4MDAxIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzc5OTU1MDg3LCJleHAiOjE3Nzk5NTU5ODd9.ogsT19L_PeFYkBAi9LUbyFNKszMrUuZ-tSgigY1UHc0"

echo "=== Test Subscription with Token ==="
curl -s http://127.0.0.1:3000/api/v1/subscription \
  -H "Authorization: Bearer $TOKEN"
echo ""
echo ""
echo "=== Test Admin Plans ==="
curl -s http://127.0.0.1:3000/api/v1/admin/plans \
  -H "Authorization: Bearer $TOKEN"
echo ""
echo ""
echo "=== Test Plan Default Configs (plan id: need to get from plans) ==="
