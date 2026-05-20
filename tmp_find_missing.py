with open('/home/mayn/dang/lib/features/records/screens/record_detail_screen.dart', 'r') as f:
    lines = f.readlines()

# Track paren balance line by line, skipping strings
bal = 0
for i, line in enumerate(lines):
    in_string = False
    string_char = None
    result = []
    for j, ch in enumerate(line):
        if not in_string:
            if ch in '"\'':
                in_string = True
                string_char = ch
            else:
                result.append(ch)
        else:
            if ch == string_char and (j == 0 or line[j-1] != '\\'):
                in_string = False
                string_char = None
    cleaned = ''.join(result)
    o = cleaned.count('(')
    c = cleaned.count(')')
    bal += o - c
    if o != 0 or c != 0:
        print(f'{i+1}: bal={bal:>3} (+{o}-{c}) | {line.rstrip()[:70]}')

print(f'Final balance: {bal}')
