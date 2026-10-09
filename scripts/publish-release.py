"""Publish the complete, already validated build to the rolling pdf-latest release.

Invoked only by the default-branch Actions job with a contents:write token.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import sys
import time


def gh(*args):
    result = subprocess.run(['gh', *args], capture_output=True, text=True)
    if result.returncode:
        print(result.stderr, file=sys.stderr)
        raise subprocess.CalledProcessError(result.returncode, ['gh', *args])
    return result.stdout


def release_files(records):
    return ({r['pdf'] for r in records}
            | {r['booklet']['pdf'] for r in records}
            | {'manifest.json', 'SHA256SUMS', 'PRINTING.txt', 'past-exams.zip',
               'sample-exams.zip', 'past-exams-print.zip', 'sample-exams-print.zip'})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', type=Path, required=True)
    args = parser.parse_args()
    directory = args.directory.resolve()
    commit = os.environ['SOURCE_COMMIT']
    repo = os.environ['GH_REPO']
    tag = 'pdf-latest'
    records = json.loads((directory / 'manifest.json').read_text())
    expected = release_files(records)
    actual = {p.name for p in directory.iterdir() if p.is_file()}
    if actual != expected:
        raise SystemExit(f'Release file mismatch: missing={expected-actual}, extra={actual-expected}')
    # Never let a queued older build overwrite a newer default-branch build.
    default_branch = json.loads(gh('api', f'repos/{repo}'))['default_branch']
    head = json.loads(gh('api', f'repos/{repo}/commits/{default_branch}'))['sha']
    if head != commit:
        print('Default branch advanced; skip publishing this older build.')
        return
    releases = json.loads(gh('api', f'repos/{repo}/releases?per_page=100'))
    existing = next((r for r in releases if r['tag_name'] == tag), None)
    notes = (f'由提交 {commit} 自动生成，共 {len(records)} 份阅读版和 {len(records)} 份小册子打印版 PDF。\n\n'
             '各 PDF 可单独下载；past-exams.zip 收录试题、答案及 Org 资料双栏预览，sample-exams.zip 收录题型示例。'
             '同名 -print.zip 为小册子打印版，PDF 文件名以 -print.pdf 结尾。'
             '打印版使用 ISO B4 横向纸张，100% 打印、双面短边翻转；请先阅读 PRINTING.txt。'
             'manifest.json 记录源文件对应关系，SHA256SUMS 提供校验。\n')
    with tempfile.TemporaryDirectory() as tmp:
        body = Path(tmp) / 'notes.txt'
        body.write_text(notes)
        if existing:
            gh('api', '--method', 'PATCH', f'repos/{repo}/git/refs/tags/{tag}', '-f', f'sha={commit}', '-F', 'force=true')
            gh('release', 'edit', tag, '--title', 'PDF downloads', '--notes-file', str(body), '--latest')
        else:
            gh('release', 'create', tag, '--target', commit, '--title', 'PDF downloads', '--notes-file', str(body), '--latest')
        paths = [str(directory / name) for name in sorted(actual)]
        # Chunk uploads to keep command length bounded as the repository grows.
        for start in range(0, len(paths), 40):
            for attempt in range(3):
                try:
                    gh('release', 'upload', tag, *paths[start:start + 40], '--clobber')
                    break
                except subprocess.CalledProcessError:
                    if attempt == 2:
                        raise
                    time.sleep(3 * (attempt + 1))
        # Delete removed papers only after every current file has been uploaded.
        assets = json.loads(gh('release', 'view', tag, '--json', 'assets'))['assets']
        for asset in assets:
            if asset['name'] not in actual:
                gh('release', 'delete-asset', tag, asset['name'], '--yes')


if __name__ == '__main__':
    main()
