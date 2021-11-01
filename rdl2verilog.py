#!/usr/bin/python3

import sys
import os
from systemrdl import RDLCompiler, RDLCompileError
from peakrdl.verilog import VerilogExporter
import argparse

def cli(args):
    parser = argparse.ArgumentParser(description='rdl2verilog')
    # register format options
    parser.add_argument("-f", "--fname", help="register file description .rdl", action='store', type = str, default="./test/testcases/basic.rdl")
    return parser.parse_args(args)

def main(fname):
    rdlc = RDLCompiler()

    try:
        rdlc.compile_file(fname)
        root = rdlc.elaborate()
    except RDLCompileError:
        sys.exit(1)

    exporter = VerilogExporter()
    base = os.path.splitext(fname)[0]
    print('output directory: ' + base)
    exporter.export(root, base, signal_overrides = dict() )


if __name__ == '__main__':
    p = cli(sys.argv[1:])
    main(p.fname)