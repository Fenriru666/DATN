import os

def unmojibake(text):
    b = bytearray()
    i = 0
    changed = False
    while i < len(text):
        c = text[i]
        code = ord(c)
        
        # 2-byte UTF-8 sequence starting with C3 or C4
        if code in (0xC3, 0xC4) and i + 1 < len(text):
            next_code = ord(text[i+1])
            if 0x80 <= next_code <= 0xbf:
                # We found a perfectly intact 2-byte sequence
                b.extend(bytes([code, next_code]))
                i += 2
                changed = True
                continue
                
        # 3-byte UTF-8 sequence starting with E1
        if code == 0xE1 and i + 2 < len(text):
            next_code1 = ord(text[i+1])
            next_code2 = ord(text[i+2])
            if 0x80 <= next_code1 <= 0xbf and 0x80 <= next_code2 <= 0xbf:
                # Perfectly intact 3-byte sequence
                b.extend(bytes([code, next_code1, next_code2]))
                i += 3
                changed = True
                continue
        
        # Keep original character encoded normally to bytearray
        b.extend(c.encode('utf-8'))
        i += 1
        
    if changed:
        try:
            return b.decode('utf-8'), True
        except UnicodeDecodeError:
            # If our heuristic matched something that wasn't actually valid utf-8, fallback
            return text, False
    return text, False

def fix_remaining(directory):
    fixed_files = 0
    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.endswith('.dart'):
                path = os.path.join(root, f)
                try:
                    with open(path, 'r', encoding='utf-8') as file:
                        content = file.read()
                        
                    new_content, changed = unmojibake(content)
                    
                    if changed and new_content != content:
                        with open(path, 'w', encoding='utf-8') as file:
                            file.write(new_content)
                        fixed_files += 1
                        print(f"Fixed: {path}")
                except Exception as e:
                    pass
    print(f"Algorithm fixed {fixed_files} files.")

if __name__ == "__main__":
    fix_remaining(r"d:\DACN\src\datn\lib")

