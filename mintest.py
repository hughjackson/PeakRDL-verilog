#!/usr/bin/env python3

import sys
import os

import jinja2 as jj
import subprocess

from systemrdl import RDLCompiler, AddrmapNode, RegfileNode, MemNode, RegNode, FieldNode
from peakrdl.verilog.exporter import VerilogExporter
import peakrdl.verilog.peakverilog as pv

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

    root = pv.compile(rdl_file)
    modules = pv.generate(root, output_dir)
    pv.run_lint(modules, output_dir)
    pv.compile_verilog(modules, output_dir)
    pv.simulate(modules)
    print("\n-----------------------------------------------------------------\n")

print("\tALL TESTS COMPLETED\n")
