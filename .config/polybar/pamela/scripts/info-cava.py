#!/usr/bin/env python3
import argparse
import os
import signal
import subprocess
import sys
import tempfile
from pathlib import Path

# ---------- Configuration ----------

# Pywal Colors (Safe Loader)
def load_wal_colors():
    wal_file = Path.home() / '.cache' / 'wal' / 'colors'
    colors = []
    try:
        if wal_file.exists():
            with wal_file.open() as f:
                # Skip the first 2 colors (usually background/too dark)
                lines = f.readlines()[2:6] 
                for line in lines:
                    colors.append(line.strip().lstrip('#'))
    except Exception:
        pass
    
    # Fallback if wal fails
    if not colors:
        return ['fdd', 'fcc', 'fbb', 'faa']
    return colors

# Argument Parsing
parser = argparse.ArgumentParser()
parser.add_argument('-f', '--framerate', type=int, default=30) # Reduced to 30 for stability
parser.add_argument('-b', '--bars', type=int, default=8)
parser.add_argument('-e', '--extra_colors', default='wal')
parser.add_argument('-c', '--channels', choices=['stereo', 'left', 'right', 'average'], default='stereo')
opts = parser.parse_args()

# Colors
if opts.extra_colors == 'wal':
    extra_colors = load_wal_colors()
else:
    extra_colors = [c.strip(' #') for c in opts.extra_colors.split(',') if c]

# ---------- Ramp Construction (The Fix) ----------

# Standard Block Characters (Safe for all fonts)
base_ramp = [' ', '▂', '▃', '▄', '▅', '▆', '▇', '█']

# Add color tags for higher volumes
color_ramp = [f'%{{F#{c}}}█%{{F-}}' for c in extra_colors]

# Combine them
ramp = base_ramp + color_ramp
ascii_max_range = len(ramp) - 1

# ---------- Cava Config Generator ----------

channels_conf = ''
if opts.channels != 'stereo':
    channels_conf = f'channels=mono\nmono_option={opts.channels}\n'

# Create temp config
fd, cava_conf_path = tempfile.mkstemp(prefix='polybar-cava-')
os.close(fd)

with open(cava_conf_path, 'w') as f:
    f.write(
        f"""
[general]
framerate = {opts.framerate}
bars = {opts.bars}

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = {ascii_max_range}
bar_delimiter = 59
{channels_conf}
"""
    )
    # bar_delimiter 59 is semicolon ';' (Safer than space)

# ---------- Main Loop ----------

cava_proc = subprocess.Popen(
    ['cava', '-p', cava_conf_path],
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True
)

def cleanup(*_):
    try:
        cava_proc.terminate()
        cava_proc.wait(timeout=0.5)
    except Exception:
        cava_proc.kill()
    try:
        os.remove(cava_conf_path)
    except FileNotFoundError:
        pass
    sys.exit(0)

signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)

try:
    for line in cava_proc.stdout:
        # Split by semicolon (Safer)
        line = line.strip()
        if not line: continue
        
        values = line.split(';')
        
        # Build Bar
        output = []
        for v in values:
            try:
                if not v: continue
                idx = int(v)
                # Clamp index to safe range
                if idx < 0: idx = 0
                if idx >= len(ramp): idx = len(ramp) - 1
                output.append(ramp[idx])
            except ValueError:
                pass
        
        # Print with flush (Polybar needs this)
        print(''.join(output), flush=True)

except KeyboardInterrupt:
    pass
finally:
    cleanup()
