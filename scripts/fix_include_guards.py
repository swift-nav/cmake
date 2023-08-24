#!/usr/bin/env python3

#
# Copyright (C) 2021 Swift Navigation Inc.
# Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must
# be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

import sys
import re
from pathlib import Path

'''
Don't check for header guards if there are error suppression
comments somewhere in this file.

Because this is silencing a warning for a nonexistent line, we
only support the very specific NOLINT(build/header_guard) syntax,
and not the general NOLINT or NOLINT(*) syntax.
'''
def can_ignore_file(lines):
    if any("NOLINT(build/header_guard)" in line for line in lines) or any("#pragma once" in line for line in lines):
        return True
    return False

def get_expected_guard(filename):
    file_path = Path(filename)

    # Check if "include" is a direct part of the path
    if "include" in file_path.parts:
        include_index = file_path.parts.index("include")
        expected_guard_parts = file_path.parts[include_index+1:]
    else:
        # For files outside "include" directory
        if file_path.parent.name == "src":
            expected_guard_parts = file_path.parts[-3:]
        else:
            expected_guard_parts = file_path.parts[-2:]

    expected_guard = "_".join(expected_guard_parts)
    expected_guard = expected_guard.replace("++", "cpp")
    expected_guard = re.sub(r"[/\.-]", "_", expected_guard).upper()

    return expected_guard

def FixHeaderGuard(filename):
    try:
        with open(filename, "r") as target_file:
            lines = target_file.read().split("\n")

        # Remove trailing '\r'.
        # The -1 accounts for the extra trailing blank line we get from split()
        for linenum in range(len(lines) - 1):
            if lines[linenum].endswith("\r"):
                lines[linenum] = lines[linenum].rstrip("\r")
    except IOError:
        sys.stderr.write("Error opening {}\n".format(filename))
        return

    if can_ignore_file(lines):
        return

    expected_guard = get_expected_guard(filename)

    ifndef = ""
    ifndef_linenum = -1
    define = ""
    define_linenum = -1
    for linenum, line in enumerate(lines):
        linesplit = line.split()
        if len(linesplit) >= 2:
            # find the first occurrence of #ifndef and #define, save arg
            if not ifndef and linesplit[0] == "#ifndef":
                # set ifndef to the header guard presented on the #ifndef line.
                ifndef = linesplit[1]
                ifndef_linenum = linenum
            if not define and linesplit[0] == "#define":
                define = linesplit[1]
                define_linenum = linenum

    if (
        ifndef_linenum == -1
        or ifndef != expected_guard
        or define_linenum == -1
        or define != expected_guard
    ):
        if ifndef_linenum == -1:
            # file doesn't have an include guard so generate one
            lines.insert(
                0, "#ifndef %s\n#define %s\n" % (expected_guard, expected_guard)
            )
            lines.append("\n#endif")
        else:
            # need to fix
            lines[ifndef_linenum] = "#ifndef " + expected_guard
            lines[define_linenum] = "#define " + expected_guard

    # Check for copyright notice
    default_copyright = """/**
 * Copyright (C) 2022 Swift Navigation Inc.
 * Contact: Swift Navigation <dev@swiftnav.com>
 *
 * This source is subject to the license found in the file 'LICENSE' which must
 * be be distributed together with this source. All other rights reserved.
 *
 * THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
 * EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
 */"""

    # We'll say it should occur by line 10. Don't forget there's a
    # placeholder line at the front.
    for line in range(1, min(len(lines), 11)):
        if re.search(r"Copyright", lines[line], re.I):
            break
    else:  # means no copyright line was found
        # Generate a default copyright notice
        lines.insert(0, default_copyright)

    with open(filename, "w") as output_file:
        output_file.write("\n".join(lines))


def main():
    for filename in sys.argv[1:]:
        FixHeaderGuard(filename)


if __name__ == "__main__":
    main()