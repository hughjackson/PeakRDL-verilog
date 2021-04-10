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
    tb_file = os.path.join(output_dir, testcase_name + "_tb.sv")

    VerilogExporter().export(
        root, output_dir
    )

    #-------------------------------------------------------------------------------
    # Build VCS binary if it exists
    #-------------------------------------------------------------------------------
    if which('vcs') == None:
        results[case] = "Generated SV, no VCS binary found"
    else:

        proc = subprocess.run(['vcs', '-sverilog', rf_file, tb_file, '+vcs+vcdpluson'])

        if proc.returncode:
            print ("Error: vcs returned {}".format(proc.returncode))
            results[case] = "VCS compile failed"
            
        else:

            #-------------------------------------------------------------------------------
            # Run the testbench
            #-------------------------------------------------------------------------------
            proc = subprocess.run(['./simv', '-l', testcase_name+'.log'], capture_output=True, text=True)
                
            if re.search("TB: test complete", proc.stdout):
                results[case] = "Test passed"
            else:
                results[case] = "Test failed ({})".format(testcase_name+'.log')
 
    #-------------------------------------------------------------------------------
    # Verilator if it exists
    #-------------------------------------------------------------------------------
    if which('verilator') == None:
        results[case] += " - No verilator"
    else:
        proc = subprocess.run(['verilator', '--lint-only', "-Wall", rf_file])

        if proc.returncode:
            print ("Error: verilator returned {}".format(proc.returncode))
            results[case] += " - Verilator lint failed"
        else:
            results[case] += " - Verilator lint passed"
            

    print("\n\n\t{}\n\n".format(results[case]))

print("================================================")
for k,v in results.items():
    print("{:30s}: {}".format(k, v))
