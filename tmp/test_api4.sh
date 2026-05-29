#!/bin/bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4ZWE3MzU4MC1jNmYzLTRmZTAtODFkYi1hNWUyZmViZmJlMTQiLCJwaG9uZSI6IjEzODAwMTM4MDAxIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzc5OTU1MDg3LCJleHAiOjE3Nzk5NTU5ODd9.ogsT19L_PeFYkBAi9LUbyFNKszMrUuZ-tSgigY1UHc0"

echo "=== Test Plan Default Configs (trial plan) ==="
curl -s http://127.0.0.1:3000/api/v1/admin/plans/trial/default-configs \
  -H "Authorization: Bearer $TOKEN"
echo ""
echo ""
echo "=== Create Default Config ==="
curl -s -X POST http://127.0.0.1:3000/api/v1/admin/plans/trial/default-configs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"functionType":"text_analysis","modelPattern":"qwen:qwen3.6-flash"}'
echo ""
echo ""
echo "=== Get Default Configs Again ==="
curl -s http://127.0.0.1:3000/api/v1/admin/plans/trial/default-configs \
  -H "Authorization: Bearer $TOKEN"
echo ""
