#!/usr/bin/env python3
"""Verify literal Lab 3 module reuse against the included source snapshot."""
from pathlib import Path
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]

def module_body(text):
    return re.search(r'module vga_pic\(.*?endmodule', text, re.S).group()

def check():
    original = module_body((ROOT/'provenance/lab3_top.v.txt').read_text())
    reused = module_body((ROOT/'RTL/vga_pic.v').read_text())
    if original != reused:
        raise ValueError('The reused vga_pic body differs from the Lab 3 snapshot')
    digest = hashlib.sha256(reused.encode()).hexdigest()
    print('PASS Lab 3 vga_pic body equality; SHA-256 '+digest, flush=True)
    return digest

if __name__ == '__main__':
    check()
