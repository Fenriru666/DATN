import os

path = r'd:\DACN\src\datn\lib\features\auth\screens\register_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

index = text.find("Ä")
if index != -1:
    snippet = text[index:index+20]
    with open(r'd:\DACN\src\datn\dump_bytes.txt', 'w', encoding='utf-8') as out:
        out.write("Snippet:\n" + snippet + "\n\nBytes:\n")
        out.write(str([hex(ord(c)) for c in snippet]))
