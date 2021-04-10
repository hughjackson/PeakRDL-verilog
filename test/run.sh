#!/bin/bash

set -e

this_dir="$( cd "$(dirname "$0")" ; pwd -P )"

exists () {
  type "$1" >/dev/null 2>/dev/null
}

# Initialize venv
venv_bin=$this_dir/.venv/bin
python3 -m venv $this_dir/.venv

#tools
python=$venv_bin/python
pylint=$venv_bin/pylint


# Install test dependencies
$python -m pip install -U pylint setuptools pip


# Install dut
cd $this_dir/..
$python setup.py install
cd $this_dir


# Run testcases
# TODO: add unit tests (e.g. VUnit) or UVM tests


# Run lint
cd $this_dir/..
$pylint --rcfile $this_dir/pylint.rc peakrdl | tee $this_dir/lint.rpt
cd $this_dir
