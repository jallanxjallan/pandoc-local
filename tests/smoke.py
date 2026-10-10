from pathlib import Path
import subprocess, os
root=Path(__file__).resolve().parents[1]
binary=os.environ.get('PANDOC_BIN','/usr/bin/pandoc')
r=subprocess.run([binary,'--data-dir='+str(root),'--defaults='+str(root/'defaults/normalize.yaml')],input='Hello   world\n',text=True,capture_output=True)
assert r.returncode==0,r.stderr
assert r.stdout.strip()=='Hello world',repr(r.stdout)
print('Pandoc normalization fixture passed')
