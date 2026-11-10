#!/usr/bin/env python3
"""Export scalar/vector VCD signals in a short interval; times are in ns."""
import argparse, csv, re
from pathlib import Path

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('vcd',type=Path)
    ap.add_argument('-o','--output',type=Path,required=True)
    ap.add_argument('--signals',nargs='+',help='full hierarchical names; omitted = all signals')
    ap.add_argument('--start-ns',type=float,default=0)
    ap.add_argument('--end-ns',type=float,required=True)
    a=ap.parse_args()
    if a.end_ns<a.start_ns: ap.error('end must be >= start')
    scope=[]; names={}; values={}; selected=[]; units=None; timestamp=0; data=False; wrote=False
    unit_factor={'s':1e9,'ms':1e6,'us':1e3,'ns':1,'ps':1e-3,'fs':1e-6}
    a.output.parent.mkdir(parents=True,exist_ok=True)
    with a.vcd.open() as f, a.output.open('w',newline='') as out:
        writer=csv.writer(out)
        def row(t): writer.writerow([f'{t:.6f}']+[values.get(names[n],'x') for n in selected])
        for raw in f:
            line=raw.strip()
            if not line: continue
            if not data:
                if line.startswith('$timescale'):
                    spec=line
                    while '$end' not in spec: spec+=' '+next(f).strip()
                    match=re.search(r'(\d+)\s*(s|ms|us|ns|ps|fs)\b',spec)
                    if not match: raise ValueError('Unsupported timescale')
                    units=int(match[1])*unit_factor[match[2]]
                elif line.startswith('$scope'): scope.append(line.split()[2])
                elif line.startswith('$upscope'): scope.pop()
                elif line.startswith('$var'):
                    parts=line.split(); names['.'.join(scope+[parts[4]])]=parts[3]
                elif line.startswith('$enddefinitions'):
                    if units is None: raise ValueError('No VCD timescale')
                    selected=a.signals or sorted(names)
                    missing=set(selected)-names.keys()
                    if missing: raise ValueError('Signals absent from VCD: '+', '.join(sorted(missing)))
                    writer.writerow(['time_ns']+selected); data=True
            elif line.startswith('#'):
                t=timestamp*units
                if t>=a.start_ns and t<=a.end_ns: row(t); wrote=True
                new_t=int(line[1:])*units
                if not wrote and new_t>a.start_ns:
                    # The last known values are valid at the window's left edge.
                    row(a.start_ns); wrote=True
                if new_t>a.end_ns: break
                timestamp=int(line[1:])
            elif line[0] in '01xXzZ': values[line[1:]]=line[0].lower()
            elif line[0] in 'bB':
                v,code=line[1:].split(); values[code]=v.lower()
        else:
            if data and a.start_ns<=timestamp*units<=a.end_ns: row(timestamp*units)
    print(a.output)
if __name__=='__main__': main()
