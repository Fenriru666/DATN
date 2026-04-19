import os

path = r'd:\DACN\src\datn\lib\features\auth\screens\register_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

index = text.find("ăng ký")
if index != -1:
    snippet = text[index-5:index+10]
    print("Found:", repr(snippet))
    print("Bytes:", [hex(ord(c)) for c in snippet])
