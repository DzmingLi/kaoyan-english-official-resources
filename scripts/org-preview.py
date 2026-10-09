"""Render Org lists and native tables; only vocabulary uses page columns."""
from pathlib import Path
import json
import re

root = Path.cwd()
def quoted(text):
    return json.dumps(text, ensure_ascii=False)

for source in sorted((root / '资料').glob('*.org')):
    content = source.read_text()
    title = re.search(r'^#\+TITLE: (.+)$', content, re.M).group(1)
    lines, rows = [], []
    def flush_table():
        if not rows:
            return
        columns = len(rows[0])
        if any(len(row) != columns for row in rows):
            raise ValueError(f'Inconsistent Org table: {source}')
        cells = lambda row: ', '.join('text(' + quoted(cell) + ')' for cell in row)
        widths = '(1fr, 0.85fr, 1.55fr)' if columns == 3 else '(1fr, 1fr)'
        lines.append('#table(columns: ' + widths + ', inset: 6pt, stroke: 0.4pt,\n'
                     '  table.header(' + cells(rows[0]) + '),\n  '
                     + ',\n  '.join(cells(row) for row in rows[1:]) + '\n)')
        rows.clear()
    for line in content.splitlines():
        if line.startswith('|'):
            if not re.fullmatch(r'\|[-+|: ]+\|', line):
                rows.append([cell.strip() for cell in line.strip().strip('|').split('|')])
            continue
        flush_table()
        if re.match(r'^\*+ ', line):
            lines.append('#block(above: 10pt, below: 5pt, sticky: true)[#text(weight: "bold", ' + quoted(re.sub(r'^\*+ ', '', line)) + ')]')
        elif line.startswith('- '):
            lines.append('#block(above: 0pt, below: 6pt, breakable: false)[#text(' + quoted(line[2:]) + ')]')
        elif line.strip() and not line.startswith('#+'):
            lines.append('#block(above: 0pt, below: 6pt)[#text(' + quoted(line) + ')]')
    flush_table()
    body = '\n'.join(lines)
    if source.stem == '词汇表':
        body = '#columns(2, gutter: 12mm)[\n' + body + '\n]'
    target = source.with_suffix('.typ')
    target.write_text('#set page(width: 176mm, height: 250mm, margin: 14mm)\n'
                      '#set text(font: ("Times New Roman", "FZShuSong-Z01S"), size: 11pt)\n'
                      '#set par(leading: 5pt)\n#set block(spacing: 6pt)\n'
                      '#align(center)[#text(size: 16pt, weight: "bold", ' + quoted(title) + ')]\n'
                      '#v(8pt)\n' + body + '\n')
