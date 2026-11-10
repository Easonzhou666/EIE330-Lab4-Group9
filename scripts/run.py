#!/usr/bin/env python3
"""Portable Icarus runner. Only Python's standard library is required."""
import argparse, json, os, shutil, struct, subprocess, sys, zlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
TESTS = ['tb_clock_reset','tb_key_debounce','tb_key_real_time',
         'tb_screen_controller','tb_vga_timing','tb_pixel_generator','tb_lab4_top']
def png_from_ppm(src):
    with src.open('rb') as f:
        if f.readline().strip()!=b'P6': raise ValueError('Expected binary PPM')
        w,h=map(int,f.readline().split())
        if f.readline().strip()!=b'255': raise ValueError('Expected 8-bit RGB')
        data=f.read()
    if len(data)!=w*h*3: raise ValueError(f'Incomplete framebuffer: {src}')
    def chunk(k,v): return struct.pack('>I',len(v))+k+v+struct.pack('>I',zlib.crc32(k+v)&0xffffffff)
    scan=b''.join(b'\x00'+data[y*w*3:(y+1)*w*3] for y in range(h))
    src.with_suffix('.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(scan,9))+chunk(b'IEND',b''))
def command(args, log, cwd):
    p=subprocess.run(args,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    log.write_text(p.stdout,encoding='utf-8')
    if p.returncode: raise RuntimeError(f'{args[0]} failed; see {log}\n{p.stdout[-4000:]}')
    return p.stdout

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--test',choices=TESTS)
    ap.add_argument('--synth',action='store_true',help='also run generic Yosys synthesis')
    ap.add_argument('--iverilog',default=os.environ.get('IVERILOG','iverilog'))
    ap.add_argument('--vvp',default=os.environ.get('VVP','vvp'))
    ap.add_argument('--yosys',default=os.environ.get('YOSYS','yosys'))
    a=ap.parse_args()
    for program in [a.iverilog,a.vvp]+([a.yosys] if a.synth else []):
        if not shutil.which(program): ap.error(f'Tool not found: {program}; install it or supply its path.')
    build=ROOT/'build'; build.mkdir(exist_ok=True)
    rtl=sorted(str(f) for f in (ROOT/'RTL').glob('*.v'))
    command([a.iverilog,'-V'],build/'iverilog_version.log',ROOT)
    command([a.vvp,'-V'],build/'vvp_version.log',ROOT)
    results=[]
    for tb in ([a.test] if a.test else TESTS):
        folder=build/tb; folder.mkdir(exist_ok=True)
        out=folder/(tb+'.vvp')
        compile_log=command([a.iverilog,'-g2012','-Wall','-s',tb,'-o',str(out),*rtl,str(ROOT/'sim'/(tb+'.v'))],folder/'compile.log',folder)
        if compile_log.strip(): raise RuntimeError(f'Compiler diagnostics require review: {folder}/compile.log\n{compile_log}')
        output=command([a.vvp,str(out)],folder/'simulation.log',folder)
        if f'PASS {tb}:' not in output: raise RuntimeError(f'No PASS marker: {tb}')
        print(output.strip(),flush=True)
        for src in folder.glob('*.ppm'): png_from_ppm(src)
        results.append({'test':tb,'status':'PASS','compiler_diagnostics':0})
    if a.synth:
        command([a.yosys,'-V'],build/'yosys_version.log',ROOT)
        # Paths are relative to project root; ROOT itself may contain spaces.
        script='read_verilog -sv '+' '.join('RTL/'+f.name for f in sorted((ROOT/'RTL').glob('*.v')))+'; hierarchy -check -top lab4_top; proc; opt; check -assert; write_json build/rtl.json; write_rtlil build/rtl.il; stat; synth -noabc -top lab4_top; check -assert; stat; write_json build/synth.json'
        (build/'synth.ys').write_text(script+'\n',encoding='utf-8')
        output=command([a.yosys,'-s','build/synth.ys'],build/'yosys.log',ROOT)
        warnings=[line for line in output.splitlines() if 'Warning:' in line]
        if warnings: raise RuntimeError('Yosys warnings require review:\n'+'\n'.join(warnings))
        print('PASS Yosys: hierarchy, process conversion, generic synthesis (-noabc), check -assert; zero warnings',flush=True)
        results.append({'test':'yosys_generic_synthesis','status':'PASS','warnings':0})
    (build/'results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    print(f'Results: {build}')
if __name__=='__main__':
    try: main()
    except (RuntimeError,ValueError) as e: print(e,file=sys.stderr); sys.exit(1)
