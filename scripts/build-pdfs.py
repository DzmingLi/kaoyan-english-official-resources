"""Compile self-contained 201 papers that import the shared exam template."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import zipfile

from booklet import PRINTING_INSTRUCTIONS, build_booklet


def sources(root):
    papers = [p for year in root.iterdir() if year.is_dir() and re.fullmatch(r'20\d{2}', year.name)
              for p in year.glob('*.typ') if p.name in (year.name + '.typ', year.name + '-答案.typ')]
    samples = list((root / '题型示例').glob('*/*-题型示例.typ')) + list((root / '题型示例').glob('*/*-题型示例-答案.typ'))
    materials = [p for p in root.glob('*.typ') if p.with_suffix('.org').exists() and p.stem != 'README']
    return sorted(papers + samples + materials)


def output_stem(source, root):
    """Match the math repository's year-subject[-answers][-print] naming."""
    relative = source.relative_to(root)
    if re.fullmatch(r'20\d{2}', relative.parts[0]):
        suffix = '-answers' if source.stem.endswith('-答案') else ''
        return f'{relative.parts[0]}-201{suffix}'
    if len(relative.parts) == 1:
        names = {'词汇表': 'vocabulary', '国家与地区': 'country-regions', '大洲与大洋': 'continents-oceans', '一般评分标准': 'marking-criteria'}
        return '201-' + names[source.stem]
    if relative.parts[0] == '题型示例':
        suffix = '-answers' if source.stem.endswith('-答案') else ''
        return f'{source.stem.split("-", 1)[0]}-201-sample{suffix}'
    raise ValueError(f'Unsupported source: {relative}')


def has_booklet(source, root):
    relative = source.relative_to(root)
    return len(relative.parts) > 1 and (re.fullmatch(r'20\d{2}', relative.parts[0]) is not None or relative.parts[0] == '题型示例')


def print_cover_blanks(source):
    """Answer documents have no cover; only pad them to a multiple of four."""
    has_cover = not source.stem.endswith('-答案') and not source.with_suffix('.org').exists()
    return {'cover_back_blank': has_cover, 'back_cover_blank': has_cover}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--only', help='Preview one source; do not update release metadata')
    args = parser.parse_args()
    root, output = args.root.resolve(), args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    selected = sources(root)
    if args.only:
        selected = [p for p in selected if p.relative_to(root).as_posix() == args.only]
        if len(selected) != 1:
            parser.error('--only must identify one supported source')
    if not selected:
        parser.error('No sources found')

    def build(source):
        relative = source.relative_to(root)
        stem = output_stem(source, root)
        target = output / (stem + '.pdf')
        result = subprocess.run(['typst', 'compile', '--ignore-system-fonts', '--root', str(root), str(source), str(target)], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(f'{relative}\n{result.stderr}')
        if result.stderr:
            print(f'{relative}\n{result.stderr}', file=sys.stderr, flush=True)
        record = {'source': relative.as_posix(), 'pdf': target.name,
                  'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
        if has_booklet(source, root):
            print_target = output / (stem + '-print.pdf')
            layout = build_booklet(target, print_target, **print_cover_blanks(source))
            record['booklet'] = {'pdf': print_target.name,
                                 'sha256': hashlib.sha256(print_target.read_bytes()).hexdigest(),
                                 **layout}
        return record

    records, failed = [], False
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as executor:
        futures = {executor.submit(build, source): source for source in selected}
        for future in as_completed(futures):
            try:
                records.append(future.result())
                print(f'Compiled PDF source {len(records)}/{len(selected)}', flush=True)
            except Exception as error:
                print(error, file=sys.stderr, flush=True)
                failed = True
    if failed:
        raise SystemExit('Build failed; no release manifest or archives produced.')
    if args.only:
        print(f'Preview built in {output}; release metadata unchanged.', flush=True)
        return
    records.sort(key=lambda r: r['source'])
    (output / 'manifest.json').write_text(json.dumps(records, ensure_ascii=False, indent=2) + '\n')
    (output / 'PRINTING.txt').write_text(PRINTING_INSTRUCTIONS, encoding='utf-8')
    managed = [r['pdf'] for r in records] + [r['booklet']['pdf'] for r in records if 'booklet' in r]
    managed += ['manifest.json', 'PRINTING.txt']
    for group, printing in [('past-exams', False), ('past-exams', True), ('sample-exams', False), ('sample-exams', True), ('resources', False)]:
        archive_name = group + ('-print' if printing else '') + '.zip'
        managed.append(archive_name)
        with zipfile.ZipFile(output / archive_name, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
            for record in records:
                category = ('sample-exams' if record['source'].startswith('题型示例/') else
                            'past-exams' if 'booklet' in record else 'resources')
                if category == group:
                    filename = record['booklet']['pdf'] if printing else record['pdf']
                    info = zipfile.ZipInfo(filename, date_time=(1980, 1, 1, 0, 0, 0))
                    info.compress_type = zipfile.ZIP_DEFLATED
                    info.external_attr = 0o100644 << 16
                    archive.writestr(info, (output / filename).read_bytes())
            if printing:
                info = zipfile.ZipInfo('PRINTING.txt', date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o100644 << 16
                archive.writestr(info, PRINTING_INSTRUCTIONS.encode('utf-8'))
    checksums = [f'{hashlib.sha256((output / name).read_bytes()).hexdigest()}  {name}' for name in sorted(managed)]
    (output / 'SHA256SUMS').write_text('\n'.join(checksums) + '\n')
    print(f'Built {len(records)} reading PDFs and {sum("booklet" in r for r in records)} print PDFs in {output}', flush=True)


if __name__ == '__main__':
    main()
