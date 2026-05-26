import json

# 读取中文文件
with open('app_zh.arb', 'r', encoding='utf-8') as f:
    zh = json.load(f)

# 读取英文文件
with open('app_en.arb', 'r', encoding='utf-8') as f:
    en = json.load(f)

# 找出中文有但英文没有的字段
missing = {}
for key, value in zh.items():
    if key not in en:
        missing[key] = value

print(f'缺失字段数量: {len([k for k in missing if not k.startswith("@")])}')

# 合并到英文文件
en.update(missing)

# 写回英文文件
with open('app_en.arb', 'w', encoding='utf-8') as f:
    json.dump(en, f, ensure_ascii=False, indent=2)

print('已同步所有缺失字段到 app_en.arb')
