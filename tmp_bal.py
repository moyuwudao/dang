with open('/home/mayn/dang/lib/features/records/screens/record_detail_screen.dart', 'r') as f:
    lines = f.readlines()

bal = 0
for i in range(339, 510):
    l = lines[i]
    o = l.count('(')
    c = l.count(')')
    bal += o - c
    if o != 0 or c != 0:
        print(f'{i+1}: bal={bal:>3} (+{o}-{c}) | {l.rstrip()[:60]}')

print(f'Final balance: {bal}')
