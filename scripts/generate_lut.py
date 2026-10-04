#!/usr/bin/env python3
"""Generate coefficients only; never generates or converts RTL."""
import argparse, math
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument('--bits',type=int,default=12)
p.add_argument('--output',default='mem/sine_lut.hex')
a=p.parse_args()
if not 2 <= a.bits <= 20: p.error('bits must be 2..20')
count=1 << a.bits
Path(a.output).parent.mkdir(parents=True,exist_ok=True)
Path(a.output).write_text(''.join(f'{int(math.floor(32767*math.sin(math.pi*i/(2*count))+0.5)):04x}\n' for i in range(count)))
print(f'Wrote {count} coefficients to {a.output}; +90 degree endpoint is bypassed in RTL.')
