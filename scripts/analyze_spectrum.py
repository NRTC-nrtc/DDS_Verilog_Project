#!/usr/bin/env python3
"""Simulation-only coherent FFT/SFDR analysis; numpy required."""
import argparse,json
import numpy as np
p=argparse.ArgumentParser()
p.add_argument('csv',nargs='?',default='results/waveform.csv')
p.add_argument('--fs',type=float,default=100e6)
p.add_argument('--bin',type=int,default=649)
a=p.parse_args()
x=np.genfromtxt(a.csv,delimiter=',',skip_header=1)
result={}
for col,name in enumerate(('sine','cosine')):
 y=x[:,col]; spectrum=np.abs(np.fft.rfft(y-y.mean()))
 fundamental=spectrum[a.bin]
 spurs=spectrum.copy(); spurs[0]=0; spurs[a.bin]=0
 spur=int(np.argmax(spurs))
 result[name]={'samples':len(y),'frequency_hz':a.bin*a.fs/len(y),
 'sfdr_dbc':float(20*np.log10(fundamental/max(spurs[spur],1e-30))),
 'largest_spur_hz':spur*a.fs/len(y),'peak':float(np.max(np.abs(y)))}
 if int(np.argmax(spectrum))!=a.bin: raise SystemExit('Unexpected fundamental; use a coherent capture')
print(json.dumps(result,indent=2))
