#!/usr/bin/env python3
"""Capture additional report windows after the self-checking regression."""
from pathlib import Path
import subprocess, os

ROOT=Path(__file__).resolve().parents[1]
rtl=[str(p) for p in sorted((ROOT/'RTL').glob('*.v'))]
folder=ROOT/'build/traces'
folder.mkdir(parents=True,exist_ok=True)
for bench in ['trace_output','trace_lab4']:
    commands=[
        [os.environ.get('IVERILOG','iverilog'),'-g2012','-Wall','-s',bench,
         '-o',str(folder/(bench+'.vvp')),*rtl,str(ROOT/'sim'/(bench+'.v'))],
        [os.environ.get('VVP','vvp'),str(folder/(bench+'.vvp'))]]
    for suffix,cmd in zip(['compile','simulation'],commands):
        p=subprocess.run(cmd,cwd=folder,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        (folder/(bench+'.'+suffix+'.log')).write_text(p.stdout)
        if p.returncode or (suffix=='compile' and p.stdout.strip()):
            raise RuntimeError(p.stdout)
        print(p.stdout,end='')
