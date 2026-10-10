#!/usr/bin/env python3
"""Run measured dim-LCD color regressions against the actual native classifier."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[1]
source=(root/'Native/marker_core.cpp').read_text()
start=source.index('static int classifyDimLCD(')
end=source.index('\nstatic std::vector<Blob> blobsDimLCD',start)
classifier=source[start:end]
# Near-black RGB samples from real optical exposures were spuriously blue/green.
# Colored controls use the same exposures, not imagined bright renderer colors.
cases=[(32,36,42,3),(44,45,52,3),(38,46,42,3),(34,40,50,3),
       (25,34,40,3),(43,46,41,3),(35,81,161,2),(42,100,93,1),
       (119,54,74,0),(255,255,255,-1),(0,0,0,3),(54,54,54,3)]
checks='\n'.join(f'assert(classifyDimLCD({r},{g},{b})=={expected});' for r,g,b,expected in cases)
program='#include <algorithm>\n#include <cassert>\n'+classifier+'\nint main(){'+checks+'}\n'
with tempfile.TemporaryDirectory(prefix='marker-dim-lcd-') as directory:
 p=Path(directory);(p/'test.cpp').write_text(program)
 subprocess.run(['c++','-std=c++17',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True)
print(f'{len(cases)} measured-color and boundary regressions passed')
