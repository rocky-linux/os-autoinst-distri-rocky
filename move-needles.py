#!/bin/python3

# Copyright Red Hat
#
# This file is part of os-autoinst-distri-fedora.
#
# os-autoinst-distri-fedora is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Adam Williamson <awilliam@redhat.com>

"""This is a helper script for moving needles to appropriate subdirectories, by examining their
filenames and looking for existing needles with similar filenames. It's convenient if you have
to update a bunch of needles for a font change, or something, and don't want to figure out where
each one goes by hand.
"""

import argparse
import datetime
import glob
import os
import shutil
import sys

def process_needles(date, move=False):
    """Main function that does all the work. date is the date to look
    for needles from (as a string in YYYYMMDD format), move (boolean)
    is whether to actually move them or just do a dry run.
    """
    # we assume all non-template JSON files in the current directory
    # are needles
    needles = glob.glob('*json')
    needles = [needle for needle in needles if not needle.startswith('templates')]
    for needle in needles:
        cands = []
        # strip off the date
        name = str(needle).replace(f"-{date}.json", "")
        # now look for any other directory that has needle(s) starting
        # with the stripped name
        for (root, dirs, files) in os.walk('.'):
            if any(file.startswith(name) for file in files) and root != '.':
                cands.append(root)
        # if we found exactly one potential target dir, go ahead
        if len(cands) == 1:
            print(f"Move {needle} to {cands[0]}")
            if move:
                shutil.move(needle, cands[0])
                sshot = needle.replace('json', 'png')
                shutil.move(sshot, cands[0])
        # if we found more than one, just explain
        elif len(cands) > 1:
            print(f"Multiple candidates found for {needle}!")
            for (idx, cand) in enumerate(cands, 1):
                print(f"{str(idx)}: {cand}")

def parse_args(args):
    """Parse arguments with argparse."""
    parser = argparse.ArgumentParser(
        description=(
            "Helper script for moving needles to appropriate subdirectories."
        )
    )
    parser.add_argument(
        "-d", "--date", help="Date to work with, in YYYYMMDD format. Script will look for needle "
        "files with this date in their name and strip it to form the base name to look for other "
        "instances of). If not specified, script will use today's date in the local timezone",
        default=datetime.date.today().strftime("%Y%m%d")
    )
    parser.add_argument(
        "-m", "--move", help="If set, actually move files; if not set, do a dry run and only "
        "report what files would be moved", action="store_true"
    )
    return parser.parse_args(args)

def run(args):
    """Parse args and call main function with appropriate options."""
    args = parse_args(args)
    process_needles(args.date, args.move)

def main():
    """Main loop."""
    try:
        run(args=sys.argv[1:])
    except KeyboardInterrupt:
        sys.stderr.write("Interrupted, exiting...\n")
        sys.exit(1)

if __name__ == '__main__':
    main()

# vim: set textwidth=100 ts=8 et sw=4:
