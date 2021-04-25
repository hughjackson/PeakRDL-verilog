#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys

from systemrdl import RDLCompiler
from peakrdl.verilog.exporter import VerilogExporter


class overrideType:

    def __init__(self, arg):
        s = arg.split('=')
        if len(s) != 2:
            raise argparse.ArgumentTypeError("expected format is 'property=new_name'")
        self.prop = s[0]
        self.new = s[1]


    def __str__(self):
        return "{} => {}".format(self.prop, self.new)


    def __repr__(self):
        return "overrideType('{}={}')".format(self.prop, self.new)


def parse_args():
    '''Program specific argument parsing'''
    parser = argparse.ArgumentParser(description='Generate Verilog output from systemRDL')
    parser.add_argument('infile', metavar='file', type=str,
                        help='input systemRDL file')

    parser.add_argument('-I', type=str, action='append', metavar='dir',
                        help='add dir to include search path')
    parser.add_argument('--outdir', '-o', type=str, default='.',
                        help='output director (default: %(default)s)')
    parser.add_argument('--top', '-t', type=str,
                        help='specify top level addrmap (default operation will use last defined global addrmap)')
    parser.add_argument('--verbose', '-v', action='count', default=0,
                        help='set logging verbosity')

    generator = parser.add_argument_group('generator options')
    generator.add_argument('--bus', '-b', type=str, default='native',
                           help='SW access bus type (default: %(default)s)')
    generator.add_argument('-O', type=overrideType, metavar='PROP=NEW',
                           action='append', default=[],
                           help='advanced: override property output name (cannot use simulate with this option)')

    checker = parser.add_argument_group('post-generate checks')
    checker.add_argument('--lint', '-l', action='store_true',
                         help='run verilator lint on the generated verilog')
    checker.add_argument('--simulate', '-s', action='store_true',
                         help='run verilator simulation on the generated verilog')

    temp = parser.parse_args()

    if temp.O and temp.simulate:
        parser.print_usage()
        print("{}: argument --override/-O: --simulate not currently supported when using override".format(os.path.basename(__file__)))
        sys.exit(1)

    return temp


def compile_rdl(infile, incl_search_paths=None, top=None):
    '''compile the rdl'''
    rdlc = RDLCompiler()
    rdlc.compile_file(infile, incl_search_paths=incl_search_paths)
    return rdlc.elaborate(top_def_name=top).top


def generate(root, outdir, signal_overrides=None, bus='native'):
    '''generate the verilog'''
    print('Info: Generating verilog for {} in {}'.format(root.inst_name, outdir))
    modules = VerilogExporter().export(
        root,
        outdir,
        signal_overrides=signal_overrides,
        bus_type=bus,
    )
    for m in modules:
        print(" - Generated: " + ' '.join(os.path.join(outdir, '{}_{}'.format(m, k)) for k in ('rf.sv', 'tb.sv', 'tb.cpp')))

    return modules


def run_lint(modules, outdir):
    for m in modules:
        rf_file = os.path.join(outdir, '{}_rf.sv'.format(m))

        print('Info: Linting {} ({})'.format(m, rf_file))
        proc = subprocess.run(['verilator', '--lint-only', "-Wall", rf_file], check=True)

        if proc.returncode:
            print ("Error: verilator returned {}".format(proc.returncode))
            sys.exit(1)
        else:
            print (" - Lint Passed")


def compile_verilog(modules, outdir, verbosity=0):
    for m in modules:
        rf_file = os.path.join(outdir, '{}_rf.sv'.format(m))
        tb_file = os.path.join(outdir, '{}_tb.cpp'.format(m))

        print('Info: Compiling {} ({})'.format(m, rf_file))
        proc = subprocess.run(['verilator', '--cc', rf_file, '--exe', tb_file], check=True, capture_output=(verbosity < 2))
        proc = subprocess.run(['make', '-C', 'obj_dir', '-f', 'V{}_rf.mk'.format(m), 'V{}_rf'.format(m)], check=True, capture_output=(verbosity < 2))

        if proc.returncode:
            print ("Error: make returned {}".format(proc.returncode))
            sys.exit(2)
        else:
            print(" - Compiled into ./obj_dir")


def simulate(modules, verbosity=0):
    for m in modules:
        bin_file = os.path.join('obj_dir', 'V{}_rf'.format(m))

        print('Info: Simulating {} ({})'.format(m, bin_file))
        proc = subprocess.run([bin_file], check=True, capture_output=(verbosity < 1))

        if proc.returncode:
            print ("Error: sim returned {}".format(proc.returncode))
            sys.exit(4)
        else:
            print (" - Simulation Passed")


if __name__ == '__main__':
    args = parse_args()
    spec = compile_rdl(args.infile, incl_search_paths=args.I, top=args.top)
    overrides = {k.prop: k.new for k in args.O}
    blocks = generate(spec, args.outdir, signal_overrides=overrides, bus=args.bus)
    if args.lint:
        run_lint(blocks, args.outdir)
    if args.simulate:
        compile_verilog(blocks, args.outdir, verbosity=args.verbose)
        simulate(blocks, verbosity=args.verbose)
