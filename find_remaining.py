import os
import re

lib_dir = r'd:\DACN\src\datn\lib'

found_strings = set()

for root, _, files in os.walk(lib_dir):
    for f_name in files:
        if f_name.endswith('.dart'):
            path = os.path.join(root, f_name)
            with open(path, 'r', encoding='utf-8') as f:
                try:
                    text = f.read()
                    for match in re.finditer(r'([A-Za-z]*[^\x00-\x7F\s]*[ÄÃÆ][^\x00-\x7F\s]*[\w\s\-\.\?]*[^\x00-\x7F\w]*[A-Za-z]*)', text):
                        s = match.group(0).strip()
                        # Clean up surrounding valid words to just capture the broken part
                        if any(c in s for c in ['Ä', 'Ã', 'Æ']):
                            found_strings.add(s)
                except Exception as e:
                    pass

with open('d:\\DACN\\src\\datn\\remaining_bad.txt', 'w', encoding='utf-8') as f:
    for s in sorted(list(found_strings)):
        f.write(s + '\n')
