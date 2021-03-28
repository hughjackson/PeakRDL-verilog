[![Build Status](https://travis-ci.org/hughjackson/PeakRDL-verilog.svg?branch=main)](https://travis-ci.org/hughjackson/PeakRDL-verilog)

# PeakRDL-verilog
Generate Verilog register model from compiled SystemRDL input

## Installing
Install from github only at the moment.

--------------------------------------------------------------------------------

## Exporter Usage
Pass the elaborated output of the [SystemRDL Compiler](http://systemrdl-compiler.readthedocs.io)
to the exporter.

```python
import sys
from systemrdl import RDLCompiler, RDLCompileError
from peakrdl.verilog import VerilogExporter

rdlc = RDLCompiler()

try:
    rdlc.compile_file("path/to/my.rdl")
    root = rdlc.elaborate()
except RDLCompileError:
    sys.exit(1)

exporter = VerilogExporter()
exporter.export(root, "test.sv")
```

## Verification
The tool will generate a tb for your module in the same directory. This will test the HW interface

--------------------------------------------------------------------------------

## Reference

### `VerilogExporter(**kwargs)`
Constructor for the Verilog Exporter class

**Optional Parameters**

* `user_template_dir`
    * Path to a directory where user-defined template overrides are stored.
* `user_template_context`
    * Additional context variables to load into the template namespace.

### `VerilogExporter.export(node, path, **kwargs)`
Perform the export!

**Parameters**

* `node`
    * Top-level node to export. Can be the top-level `RootNode` or any internal `AddrmapNode`.
* `path`
    * Output file.

**Optional Parameters**

