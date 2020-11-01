#!/usr/bin/env python3

import sys
import os

import jinja2 as jj

from systemrdl import RDLCompiler, AddrmapNode, RegfileNode, MemNode, RegNode, FieldNode
from peakrdl.verilog.exporter import VerilogExporter

#-------------------------------------------------------------------------------
testcase_name = sys.argv[1]
rdl_file = sys.argv[2]
output_dir = os.path.dirname(rdl_file)
#-------------------------------------------------------------------------------
# Generate Verilog model
#-------------------------------------------------------------------------------
rdlc = RDLCompiler()
rdlc.compile_file(rdl_file)
root = rdlc.elaborate().top

verilog_exportname = os.path.join(output_dir, testcase_name + "_verilog.sv")

VerilogExporter().export(
    root, verilog_exportname,
)
