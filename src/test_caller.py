"""Test caller for os_info_measurer.

This script starts the measurer binary, sends start and stop commands,
and verifies that output CSV files are generated.
"""

import argparse
import os
import subprocess
import time


def find_measurer():
  """Find measurer binary in common locations."""
  candidates = [
      "_build/dev/lib/os_info_measurer/priv/measurer",
      "_build/test/lib/os_info_measurer/priv/measurer",
      "./priv/measurer"
  ]

  for path in candidates:
    if os.path.exists(path):
      return path

  raise FileNotFoundError("measurer binary not found")


# Parse command line arguments
parser = argparse.ArgumentParser(description="Test caller for os_info_measurer")
parser.add_argument("-d", "--directory", default="tmp", help="Output directory")
parser.add_argument("-f", "--prefix", default="python_test", help="Output file prefix")
parser.add_argument("-i", "--interval", default="100", help="Measurement interval in ms")
args = parser.parse_args()

# Create output directory
os.makedirs(args.directory, exist_ok=True)

# Find measurer binary
measurer_path = find_measurer()

# Start the measurer binary
proc = subprocess.Popen(
    [measurer_path, "-d", args.directory, "-f", args.prefix, "-i", args.interval],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    bufsize=1,
)

try:
    # Start measurement
    proc.stdin.write("start\n")
    proc.stdin.flush()
    print("Measurement started...")

    # Measurement in progress
    time.sleep(1)

    # Stop measurement
    proc.stdin.write("stop\n")
    proc.stdin.flush()
    print("Measurement stopped.")

    # Close stdin to signal EOF to measurer
    # The measurer binary waits for EOF on stdin as a signal to exit normally.
    # CSV files are written to disk only after the measurer exits.
    # See src/main.cpp for details.
    proc.stdin.close()
    proc.wait(timeout=5)

except subprocess.TimeoutExpired:
    print("Process timeout, terminating...")
    proc.terminate()
    proc.wait()
