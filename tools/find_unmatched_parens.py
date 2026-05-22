from pathlib import Path
s = Path('lib/screens/event_detail_screen.dart').read_text(encoding='utf-8')
stack=[]
for i,ch in enumerate(s):
    if ch=='(':
        stack.append(i)
    elif ch==')':
        if stack:
            stack.pop()
        else:
            print('Unmatched ) at char',i)
if stack:
    print('Unmatched ( count',len(stack),'first at char index',stack[0])
    # show line number and snippet
    idx = stack[0]
    lines = s.splitlines()
    cum=0
    for lineno, line in enumerate(lines, start=1):
        cum += len(line)+1
        if cum>idx:
            print('first unmatched ( at line',lineno)
            print('line content:',line)
            break
else:
    print('All matched')
