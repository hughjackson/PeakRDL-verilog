#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys

from systemrdl import RDLCompiler
from peakrdl.verilog.exporter import VerilogExporter


def parse_args():
    '''Program specific argument parsing'''
    parser = argparse.ArgumentParser(description='Generate Verilog output from systemRDL')
    parser.add_argument('infile', metavar='N', type=str,
                        help='input systemRDL file')
    parser.add_argument('--outdir', '-o', type=str, default='.',
                        help='output director (default: %(default)s)')

    return parser.parse_args()


def compile_rdl(infile):
    '''compile the rdl'''
    rdlc = RDLCompiler()
    rdlc.compile_file(infile)
    return rdlc.elaborate().top


def generate(root, outdir):
    '''generate the verilog'''
    print('Info: Generating verilog for {}'.format(root.inst_name))
    modules = VerilogExporter().export(
        root, outdir
    )

    return modules


def run_lint(modules, outdir):
    for m in modules:
        rf_file = os.path.join(outdir, '{}_rf.sv'.format(m))

        print('Info: Linting {} ({})'.format(m, rf_file))
        proc = subprocess.run(['verilator', '--lint-only', "-Wall", rf_file], check=True)

        if proc.returncode:
            print ("Error: verilator returned {}".format(proc.returncode))
            sys.exit(1)


def compile_verilog(modules, outdir):
    for m in modules:
        rf_file = os.path.join(outdir, '{}_rf.sv'.format(m))
        tb_file = os.path.join(outdir, '{}_tb.cpp'.format(m))

        print('Info: Compiling {} ({})'.format(m, rf_file))
        proc = subprocess.run(['verilator', '--cc', rf_file, '--exe', tb_file], check=True)
        proc = subprocess.run(['make', '-C', 'obj_dir', '-f', 'V{}_rf.mk'.format(m), 'V{}_rf'.format(m)], check=True)

        if proc.returncode:
            print ("Error: make returned {}".format(proc.returncode))
            sys.exit(2)


def simulate(modules):
    for m in modules:
        bin_file = os.path.join('obj_dir', 'V{}_rf'.format(m))

        print('Info: Simulating {} ({})'.format(m, bin_file))
        proc = subprocess.run([bin_file], check=True)

        if proc.returncode:
            print ("Error: sim returned {}".format(proc.returncode))
            sys.exit(4)
        else:
            print ("Info: simulation PASSED")


if __name__ == '__main__':
    args = parse_args()
    spec = compile_rdl(args.infile)
    blocks = generate(spec, args.outdir)
    run_lint(blocks, args.outdir)
    compile_verilog(blocks, args.outdir)
    simulate(blocks)
