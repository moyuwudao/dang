with open('/home/mayn/dang/lib/features/records/screens/record_detail_screen.dart', 'r') as f:
    c = f.read()

# Remove string literals
in_string = False
string_char = None
result = []
for i, ch in enumerate(c):
    if not in_string:
        if ch in '"\'':
            in_string = True
            string_char = ch
        else:
            result.append(ch)
    else:
        if ch == string_char and (i == 0 or c[i-1] != '\\'):
            in_string = False
            string_char = None

cleaned = ''.join(result)
opens = cleaned.count('(')
closes = cleaned.count(')')
print(f'opens={opens}, closes={closes}, diff={opens-closes}')
