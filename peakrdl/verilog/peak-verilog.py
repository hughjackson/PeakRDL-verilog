#!/usr/bin/env python3
import argparse
import os
import subprocess
from systemrdl import RDLCompiler
from peakrdl.verilog.exporter import VerilogExporter
from shutil import which


def parse_args():
    '''Program specific argument parsing'''
    parser = argparse.ArgumentParser(description='Generate Verilog output from systemRDL')
    parser.add_argument('infile', metavar='N', type=str,
                        help='input systemRDL file')
    parser.add_argument('--outdir', '-o', type=str, default='.',
                        help='output director (default: %(default)s)')

    return parser.parse_args()


def compile():
    '''compile the rdl'''
    rdlc = RDLCompiler()
    rdlc.compile_file(args.infile)
    return rdlc.elaborate().top


def generate(root):
    '''generate the verilog'''
    print('Info: Generating verilog for {} ({})'.format(root.inst_name, args.infile))
    modules = VerilogExporter().export(
        root, args.outdir
    )

    return modules


def run_lint(modules):
    for m in modules:
        rf_file = os.path.join(args.outdir, '{}_rf.sv'.format(m))

        print('Info: Linting {} ({})'.format(m, rf_file))
        proc = subprocess.run(['verilator', '--lint-only', "-Wall", rf_file])

        if proc.returncode:
            print ("Error: verilator returned {}".format(proc.returncode))
            exit(1)


def compile_verilog(modules):
    for m in modules:
        rf_file = os.path.join(args.outdir, '{}_rf.sv'.format(m))
        tb_file = os.path.join(args.outdir, '{}_tb.cpp'.format(m))

        print('Info: Compiling {} ({})'.format(m, rf_file))
        proc = subprocess.run(['verilator', '--cc', rf_file, '--exe', tb_file])
        proc = subprocess.run(['make', '-C', 'obj_dir', '-f', 'V{}_rf.mk'.format(m), 'V{}_rf'.format(m)])

        if proc.returncode:
            print ("Error: make returned {}".format(proc.returncode))
            exit(2)


def simulate(modules):
    for m in modules:
        bin_file = os.path.join('obj_dir', 'V{}_rf'.format(m))

        print('Info: Simulating {} ({})'.format(m, bin_file))
        proc = subprocess.run([bin_file])

        if proc.returncode:
            print ("Error: sim returned {}".format(proc.returncode))
            exit(4)
        else:
            print ("Info: simulation PASSED")


if __name__ == '__main__':
    '''Main entry point'''
    args = parse_args()
    root = compile()
    modules = generate(root)
    run_lint(modules)
    compile_verilog(modules)
    simulate(modules)