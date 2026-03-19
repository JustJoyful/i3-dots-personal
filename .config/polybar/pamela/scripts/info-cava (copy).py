#!/usr/bin/env python3
from pathlib import Path
import argparse
import os
import signal
import subprocess
import sys
import tempfile

#Pywal My AHH
def load_wal_colors(n=4):
    wal_file = Path.home() / '.cache' / 'wal' / 'colors'
    if not wal_file.exists():
        return []

    colors = []
    with wal_file.open() as f:
        for line in f:
            line = line.strip().lstrip('#')
            if len(line) == 6:
                colors.append(line)

    # Skip black/white, take mid-range colors
    return colors[2:2+n]


# ---------- Argument parsing ----------

parser = argparse.ArgumentParser()
parser.add_argument('-f', '--framerate', type=int, default=60)
parser.add_argument('-b', '--bars', type=int, default=8)
parser.add_argument(
    '-e', '--extra_colors',
    default='fdd,fcc,fbb,faa',
    help='Comma-separated hex colors'
)
parser.add_argument(
    '-c', '--channels',
    choices=['stereo', 'left', 'right', 'average'],
    default='stereo'
)

opts = parser.parse_args()

if opts.extra_colors == 'wal':
    extra_colors = load_wal_colors(4)
else:
    extra_colors = [c.strip(' #') for c in opts.extra_colors.split(',') if c]


# ---------- Ramp setup ----------

base_ramp = [' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']
color_ramp = [
    f'%{{F#{c.strip(" #")}}}█%{{F-}}'
    for c in extra_colors
]
ramp = base_ramp + color_ramp

ascii_max_range = len(ramp) - 1

# ---------- Cava config ----------

channels_conf = ''
if opts.channels != 'stereo':
    channels_conf = (
        'channels=mono\n'
        f'mono_option={opts.channels}\n'
    )

fd, cava_conf_path = tempfile.mkstemp(prefix='polybar-cava-')
os.close(fd)

with open(cava_conf_path, 'w') as f:
    f.write(
        '[general]\n'
        f'framerate={opts.framerate}\n'
        f'bars={opts.bars}\n'
        '[output]\n'
        'method=raw\n'
        'data_format=ascii\n'
        f'ascii_max_range={ascii_max_range}\n'
        'bar_delimiter=32\n'
        + channels_conf
    )

# ---------- Process management ----------

cava_proc = subprocess.Popen(
    ['cava', '-p', cava_conf_path],
    stdout=subprocess.PIPE,
    text=True
)

def cleanup(*_):
    try:
        cava_proc.terminate()
        cava_proc.wait(timeout=1)
    except Exception:
        cava_proc.kill()
    try:
        os.remove(cava_conf_path)
    except FileNotFoundError:
        pass
    sys.exit(0)

signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)

# ---------- Main loop ----------

try:
    for line in cava_proc.stdout:
        values = line.strip().split()
        output = []
        for v in values:
            try:
                idx = int(v)
            except ValueError:
                idx = 0
            if idx >= len(ramp):
                idx = len(ramp) - 1
            output.append(ramp[idx])
        print(''.join(output), flush=True)
except KeyboardInterrupt:
    pass
finally:
    cleanup()

