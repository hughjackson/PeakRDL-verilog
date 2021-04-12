#!/usr/bin/env python3

import sys
import os

import jinja2 as jj
import subprocess

from systemrdl import RDLCompiler, AddrmapNode, RegfileNode, MemNode, RegNode, FieldNode
from peakrdl.verilog.exporter import VerilogExporter
from glob import glob
from shutil import which
import re

if len(sys.argv) == 1:
    testcases = glob('test/testcases/*.rdl')
else:
    testcases = glob('test/testcases/{}.rdl'.format(sys.argv[1]))

#-------------------------------------------------------------------------------
results = {}
for case in testcases:
    print("Case: ", case)
    rdl_file = case
    testcase_name = os.path.splitext(os.path.basename(case))[0]
    output_dir = os.path.dirname(rdl_file)

    #-------------------------------------------------------------------------------
    # Generate Verilog model
    #-------------------------------------------------------------------------------
    rdlc = RDLCompiler()
    rdlc.compile_file(rdl_file)
    root = rdlc.elaborate().top

    rf_file = os.path.join(output_dir, testcase_name + "_rf.sv")
    ctb_file = os.path.join(output_dir, testcase_name + "_tb.cpp")

    VerilogExporter().export(
        root, output_dir
    )
 
    #-------------------------------------------------------------------------------
    # Verilator
    #-------------------------------------------------------------------------------
    if which('verilator') == None:
        results[case] = "No verilator"
    else:
        proc = subprocess.run(['verilator', '--lint-only', "-Wall", rf_file])

        if proc.returncode:
            print ("Error: verilator returned {}".format(proc.returncode))
            results[case] = "Verilator lint failed"
            continue
            
        proc = subprocess.run(['verilator', '--cc', rf_file, '--exe', ctb_file])

        if proc.returncode:
            print ("Error: verilator returned {}".format(proc.returncode))
            results[case] = "Verilator compile failed"
            continue

        proc = subprocess.run(['make', '-C', 'obj_dir', '-f', 'V{}_rf.mk'.format(testcase_name), 'V{}_rf'.format(testcase_name)])
        
        if proc.returncode:
            print ("Error: gcc returned {}".format(proc.returncode))
            results[case] = "GCC compile failed"
            continue

        proc = subprocess.run(['./obj_dir/V{}_rf'.format(testcase_name)])

        if proc.returncode:
            print ("Error: sim returned {}".format(proc.returncode))
            results[case] = "Verilator Simulation failed"
            continue
        else:
            results[case] = "Verilator Simulation passed"

    print("\n\n\t{}\n\n".format(results[case]))

print("================================================")
for k,v in results.items():
    print("{:30s}: {}".format(k, v))
