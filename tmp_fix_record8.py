with open('/home/mayn/dang/lib/features/records/screens/record_detail_screen.dart', 'r') as f:
    lines = f.readlines()

# Fix line 503-508
lines[502] = '                    ],\n'
lines[503] = '                  ),\n'
lines[504] = '                ),\n'
lines[505] = '              ),\n'
lines[506] = '            ),\n'
lines[507] = '          ],\n'
lines[508] = '        ),\n'
lines[509] = '      );\n'

with open('/home/mayn/dang/lib/features/records/screens/record_detail_screen.dart', 'w') as f:
    f.writelines(lines)
print('Fixed closing structure!')
