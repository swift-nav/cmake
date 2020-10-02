#!/usr/bin/env python
#
# This script uses a file generated by the profiling tool Bloaty as input
# and writes the static size of the binary when loaded into memory, VM size,
# into a log file.
#
# USAGE
#
#   python parse_bloaty.py [OPTIONS]
#
# Run the script by supplying an input file path to a Bloaty file and a file path
# to where the log file should be created.
#
# OPTIONS
# * -i, --input_file:  Sets the input file path.
# * -o, --output_file: Sets the output file path.
# * -m, --message:     Adds a message to the reported memory usage.
#
import sys, argparse

parser = argparse.ArgumentParser(description='Log total static memory size reported by Bloaty.')
optional = parser._action_groups.pop()
required = parser.add_argument_group('required arguments')
required.add_argument('-i','--input_file',
                      help='File path where a Bloaty file is located',
                      required=True)
required.add_argument('-o','--output_file',
                      help='File path where the log should be created',
                      required=True)
optional.add_argument('-m','--message',
                      help='Custom message that gets concatenated with the reported memory usage',
                      default='Static memory usage:')
parser._action_groups.append(optional)
args = parser.parse_args()

try:
  finput = open(args.input_file)
  foutput = open(args.output_file,"a")
except IOError:
  exit()

with finput:
  lines = finput.readlines()
  last_line = lines[-1]

  end = last_line.rfind("TOTAL")-4
  start = last_line.rfind(" ",0,end)

  result = last_line[start:end].strip()
  message = "{} {}\n".format(args.message, result)
  foutput.write(message)
finput.close()
foutput.close()

