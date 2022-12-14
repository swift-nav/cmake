#!/usr/bin/env python3

import sys
import re
import yaml
import argparse


LINE = "(?P<line_number>[0-9]+)"
COLUMN = "(?P<column_number>[0-9]+)"
FILENAME = "(?P<filename>.+)"
CHECK = "(?P<check_name>[a-z-]+)"
extract_check = re.compile(
    f"^{FILENAME}:{LINE}:{COLUMN}:[ ]+(warning|error):[^[]+\[{CHECK}\]$"
)


def load_count_reference(reference_file):
    return yaml.safe_load(reference_file) or {}


def emit_checks_as_yaml(results):
    return yaml.dump(results)


def get_check_counts(clang_tidy_output):
    """Return a map from check name to the number of occurrences in
    the given output.

    """
    results = {}
    for line in clang_tidy_output:
        found = extract_check.search(line)
        if found:
            check_name = found["check_name"]
            # Save a set of tuples identifying where the problem
            # occurred.  This is intended to prevent situations like
            # the count of issues going up when someone `#include`s a
            # known problematic header in a new source file.
            results[check_name] = results.setdefault(check_name, set()) | set(
                [(found["filename"], found["line_number"], found["column_number"])]
            )

    return {check: len(locations) for check, locations in results.items()}


def compare(results, reference):
    """Compute deltas between the results and the reference.

    Returns a tuple containing a map of keys to deltas for violations,
    a map of keys to deltas for improvements and a map containing the
    recommended reference file contents.

    """
    results_only = set(results) - set(reference)
    reference_only = set(reference) - set(results)
    both = set(results) & set(reference)

    def make_delta(key):
        return (reference.get(key, 0), results.get(key, 0))

    violations = {key: make_delta(key) for key in results_only}
    improvements = {}
    recommended = {key: reference[key] for key in reference}
    for key in both:
        if results[key] > reference[key]:
            violations[key] = make_delta(key)
        elif results[key] < reference[key]:
            recommended[key] = results[key]
            improvements[key] = make_delta(key)

    for key in reference_only:
        improvements[key] = make_delta(key)
        del recommended[key]

    return violations, improvements, recommended


def render_delta(delta):
    return "\n".join(
        [f"  {key}:\t{delta[key][0]}  -->  {delta[key][1]}" for key in delta]
    )


HEADER = "\n  == cmake/scripts/clang_tidy_ratchet.py ==\n"


def display_comparison(comparison_results, reference_filename):
    """Displays the comparison results for human consumption.

    Returns a positive number if changes are required (ratchet check
    failure) or 0 if all is well.

    """
    violations, improvements, recommended = comparison_results

    if violations:
        print(HEADER)
        print("ERROR: You have increased the number of clang-tidy warnings:\n")
        print(render_delta(violations))
        print("\nPlease inspect the clang-tidy results and revise your patch.")
        return 1

    if improvements:
        print(HEADER)
        print("CONGRATULATIONS: you have reduced the number of clang-tidy warnings:\n")
        print(render_delta(improvements))
        print(
            f"\nPlease update the reference file '{reference_filename}' to contain:\n"
        )
        print(emit_checks_as_yaml(recommended))
        return 2

    return 0


EPILOG = """ clang-tidy comes with a built-in exclusion system, but it
requires specific line numbers, which may change arbitrarily as the
code is updated.  This program, in contrast, ignores specific
locations and simply counts the number of unique occurrences of each
check reported by clang-tidy, then compares these to the counts in the
given reference (whitelist) file.  Counts that have increased are
reported as errors.  If no errors have occurred, counts that have
decreased are reported as improvements to be applied to the reference
file and code-reviewed.

"""


def main():
    parser = argparse.ArgumentParser(
        "clang_tidy_ratchet.py",
        description="Validate current clang-tidy warning counts.",
        epilog=EPILOG,
    )
    parser.add_argument(
        "--reference",
        required=True,
        type=argparse.FileType("r"),
        help="Path to yaml reference warning counts",
    )
    parser.add_argument(
        "--clang_tidy_output",
        default="-",
        type=argparse.FileType("r"),
        help="Path to clang-tidy warning output",
    )
    args = parser.parse_args()
    reference = load_count_reference(args.reference)
    results = get_check_counts(args.clang_tidy_output)
    comparison = compare(results, reference)
    sys.exit(display_comparison(comparison, args.reference.name))


if __name__ == "__main__":
    main()
