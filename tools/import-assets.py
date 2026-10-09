#!/usr/bin/env python3
from pathlib import Path
import argparse,json,shutil
p=argparse.ArgumentParser();p.add_argument('--folder',required=True);p.add_argument('--source',required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];source=Path(a.source).resolve();rows=json.loads((root/'assets-required.json').read_text());allowed={row['folder'] for row in rows}
if a.folder not in allowed:raise SystemExit('Unknown folder')
count=0
for row in rows:
 if row['folder']!=a.folder:continue
 rel=Path(row['path'])
 if rel.is_absolute() or '..' in rel.parts:raise SystemExit('Unsafe asset path')
 src=source/rel;dst=root/a.folder/rel
 if not src.exists():continue
 if src.is_symlink() or not src.is_file() or not src.resolve().is_relative_to(source):raise SystemExit('Unsafe source asset')
 dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst);count+=1
print(f'Imported {count} authorized assets. Keep private assets out of public commits.')
