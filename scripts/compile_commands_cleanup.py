#!/usr/bin/env python3

#
# Application will allow users to strip away source files from the compile_commands.json file.
#

import argparse
import json
import sys

parser = argparse.ArgumentParser(description="Modifies a compile_commands.json file", allow_abbrev=False)
parser.add_argument("file", type=str, help="path to the compile_commands.json file")
parser.add_argument("--remove-third-party", action="store_true", help="removes all third party files")
arguments = parser.parse_args()

try:
    with open(arguments.file, "r") as file:
        data = json.load(file)

    if arguments.remove_third_party:
        data = [x for x in data if "third_party" not in x["file"]]

    with open(arguments.file, "w") as file:
        json.dump(data, file, indent=4)
except BaseException as e:
    print(e, file=sys.stderr)
    exit(1)
