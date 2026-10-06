#!/usr/bin/env python3
"""Controlled curl replacement; installation still hashes and executes real bytes."""
import os
from pathlib import Path
import shutil
import signal
import sys
import time

args = sys.argv[1:]
if '--output' not in args or args[-1] != os.environ['REVOFMT_EXPECT_URL']:
    sys.stderr.write('unexpected download request')
    sys.exit(2)
with open(os.environ['REVOFMT_DOWNLOAD_LOG'], 'a') as log:
    log.write(args[-1] + '\n')
output = Path(args[args.index('--output') + 1])
mode = os.environ.get('REVOFMT_DOWNLOAD_MODE', 'success')
if mode == 'delay':
    time.sleep(0.15)
if mode == 'signal':
    os.kill(os.getpid(), signal.SIGTERM)
if mode == 'failure':
    output.write_bytes(b'partial download')
    sys.stderr.write('controlled HTTP failure')
    sys.exit(22)
if mode == 'mismatch':
    output.write_bytes(b'wrong binary')
elif mode == 'oversize':
    output.write_bytes(b'x' * 16777217)
else:
    shutil.copyfile(os.environ['REVOFMT_BIN'], output)
