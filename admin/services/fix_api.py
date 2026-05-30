#!/usr/bin/env python3
import re

with open('api.ts', 'r') as f:
    content = f.read()

# 修复 getPlanById
content = content.replace(
    "await axiosInstance.get<ApiResponse<any>>(/admin/plans/);",
    "await axiosInstance.get<ApiResponse<any>>(`/admin/plans/${id}`);"
)

# 修复 updatePlan
content = content.replace(
    "await axiosInstance.put<ApiResponse<any>>(`/admin/plans/${id}`, plan);",
    "await axiosInstance.put<ApiResponse<any>>(`/admin/plans/${id}`, plan);"
)

# 修复 deletePlan
content = content.replace(
    "await axiosInstance.delete(`/admin/plans/${id}`);",
    "await axiosInstance.delete(`/admin/plans/${id}`);"
)

with open('api.ts', 'w') as f:
    f.write(content)

print('Fixed all template strings')
