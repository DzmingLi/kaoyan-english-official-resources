"""Render the repository's simple Org list documents with Typst."""
from pathlib import Path
import json,re
root=Path.cwd()
for source in sorted((root/'资料').glob('*.org')):
    title=re.search(r'^#\+TITLE: (.+)$',source.read_text(),re.M).group(1)
    lines=[]
    for line in source.read_text().splitlines():
        if line.startswith('* '): lines.append('#block(above: 10pt, below: 5pt)[#text(weight: "bold", '+json.dumps(line[2:],ensure_ascii=False)+')]')
        elif line.startswith('- '): lines.append('#block(above: 0pt, below: 3pt, breakable: false)[#text('+json.dumps(line[2:],ensure_ascii=False)+')]')
    target=root/'资料'/(''+source.stem+'.typ')
    target.write_text('#set page(width: 176mm, height: 250mm, margin: 14mm)\n#set text(font: ("Times New Roman", "FZShuSong-Z01S"), size: 11pt)\n#set par(leading: 5pt)\n#align(center)[#text(size: 16pt, weight: "bold", '+json.dumps(title,ensure_ascii=False)+')]\n#v(8pt)\n#columns(2, gutter: 12mm)[\n'+'\n'.join(lines)+'\n]\n')
