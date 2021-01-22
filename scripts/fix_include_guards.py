#!/usr/bin/env python3

import codecs
import sys
import re

def FixHeaderGuard(filename):
  try:
    with codecs.open(filename, 'r', 'utf8', 'replace') as target_file:
      lines = target_file.read().split('\n')

    # Remove trailing '\r'.
    # The -1 accounts for the extra trailing blank line we get from split()
    for linenum in range(len(lines) - 1):
      if lines[linenum].endswith('\r'):
        lines[linenum] = lines[linenum].rstrip('\r')

  except IOError:
    sys.stderr.write(
        "Skipping input '%s': Can't open for reading\n" % filename)
    return

  # Don't check for header guards if there are error suppression
  # comments somewhere in this file.
  #
  # Because this is silencing a warning for a nonexistent line, we
  # only support the very specific NOLINT(build/header_guard) syntax,
  # and not the general NOLINT or NOLINT(*) syntax.
  raw_lines = lines
  for i in raw_lines:
    if re.match(r'//\s*NOLINT\(build/header_guard\)', i):
      return

  # Allow pragma once instead of header guards
  for i in raw_lines:
    if re.match(r'^\s*#pragma\s+once', i):
      return

  if re.match(r'.*/include/.*', filename):
    expected_guard = re.sub(r'^.*/include/', '', filename)
  else:
    # header is probably just loose in a source directory as a private include
    # therefore just use the parent directory name as a prefix
    expected_guard = '_'.join(filename.split('/')[-2:])

  expected_guard = re.sub(r'\+\+', 'cpp', expected_guard)
  expected_guard = re.sub(r'[/\.]', '_', expected_guard).upper()

  sys.stdout.write('Expected guard: %s\n' % expected_guard)

  ifndef = ''
  ifndef_linenum = -1
  define = ''
  define_linenum = -1
  for linenum, line in enumerate(raw_lines):
    linesplit = line.split()
    if len(linesplit) >= 2:
      # find the first occurrence of #ifndef and #define, save arg
      if not ifndef and linesplit[0] == '#ifndef':
        # set ifndef to the header guard presented on the #ifndef line.
        ifndef = linesplit[1]
        ifndef_linenum = linenum
      if not define and linesplit[0] == '#define':
        define = linesplit[1]
        define_linenum = linenum

  if ifndef_linenum > -1 and ifndef == expected_guard and define_linenum > -1 and define == expected_guard:
        return

  if ifndef_linenum == -1:
    # file doesn't have an include guard so generate one
    lines.insert(0, "#ifndef %s\n#define %s\n" % (expected_guard, expected_guard))
    lines.append("\n#endif")
  else: 
    # need to fix
    lines[ifndef_linenum] = "#ifndef " + expected_guard
    lines[define_linenum] = "#define " + expected_guard

  with codecs.open(filename, 'w', 'utf8', 'replace') as output_file:
    output_file.write('\n'.join(lines))

def main():
    for filename in sys.argv[1:]:
        FixHeaderGuard(filename)

if __name__ == '__main__':
    main()

