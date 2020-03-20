#!/usr/bin/python3

# Copyright (C) 2020 Red Hat
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

"""This is a check script which checks for unused needles. If none of
the tags a needle declares is referenced in the tests, it is
considered unused.
"""

import glob
import json
import os
import re
import sys

NEEDLEPATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), "needles")
TESTSPATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), "tests")
LIBPATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), "lib")
# these don't account for escaping, but I don't think we're ever going
# to have an escaped quotation mark in a needle tag
DOUBLEQUOTERE = re.compile('"(.*?)"')
SINGLEQUOTERE = re.compile("'(.*?)'")

# first we're gonna build a big list of all string literals
testpaths = glob.glob(f"{TESTSPATH}/**/*.pm", recursive=True)
testpaths.extend(glob.glob(f"{LIBPATH}/**/*.pm", recursive=True))
testliterals = []
for testpath in testpaths:
    # skip if it's a symlink
    if os.path.islink(testpath):
        continue
    # otherwise, scan it for string literals
    with open(testpath, "r") as testfh:
        testtext = testfh.read()
    for match in DOUBLEQUOTERE.finditer(testtext):
        testliterals.append(match[1])
    for match in SINGLEQUOTERE.finditer(testtext):
        testliterals.append(match[1])

# now let's do some whitelisting, for awkward cases where we know that
# we concatenate string literals and stuff
# versioned backgrounds and release IDs
for rel in range(30, 100):
    testliterals.append(f"{rel}_background")
    testliterals.append(f"version_{rel}_ident")
# anaconda id needles, using tell_source
for source in ("workstation", "generic", "server"):
    testliterals.append(f"leftbar_{source}")
    testliterals.append(f"topbar_{source}")
# keyboard layout switching, using desktop_switch_layout
for environment in ("anaconda", "gnome"):
    for layout in ("native", "ascii"):
        testliterals.append(f"{environment}_layout_{layout}")
# package set selection, using get_var('PACKAGE_SET')
for pkgset in ("kde", "workstation", "minimal"):
    testliterals.append(f"anaconda_{pkgset}_highlighted")
    testliterals.append(f"anaconda_{pkgset}_selected")
# desktop_login stuff
for user in ("jack", "jim"):
    testliterals.append(f"login_{user}")
    testliterals.append(f"user_confirm_{user}")
# partitioning stuff, there's a bunch of this, all in anaconda.pm
# multiple things use this
for part in ("swap", "root"):
    testliterals.append(f"anaconda_part_select_{part}")
# select_disks
for num in range(1, 10):
    testliterals.append(f"anaconda_install_destination_select_disk_{num}")
# custom_scheme_select
for scheme in ("standard", "lvmthin", "btrfs"):
    testliterals.append(f"anaconda_part_scheme_{scheme}")
# custom_blivet_add_partition
for dtype in ("lvm", "lvmthin", "raid"):
    testliterals.append(f"anaconda_blivet_part_devicetype_{dtype}")
for fsys in ("ext3", "ext4", "xfs", "btrfs", "ppc_prep_boot", "swap", "efi_filesystem"):
    testliterals.append(f"anaconda_blivet_part_fs_{fsys}")
    testliterals.append(f"anaconda_blivet_part_fs_{fsys}_selected")
# this is variable-y in custom_change_type but we only actually have
# one value
testliterals.append("anaconda_part_device_type_raid")
# custom_change_fs
for fsys in ("ext3", "xfs"):
    testliterals.append(f"anaconda_part_fs_{fsys}")
    testliterals.append(f"anaconda_part_fs_{fsys}_selected")
# variable-y in custom_change_device but we only have one value
testliterals.append("anaconda_part_device_sda")

# retcode tracker
ret = 0

# now let's scan our needles
unused = []
noimg = []
noneedle = []

needlepaths = glob.glob(f"{NEEDLEPATH}/**/*.json", recursive=True)
for needlepath in needlepaths:
    # check we have a matching image file
    imgpath = needlepath.replace(".json", ".png")
    if not os.path.exists(imgpath):
        noimg.append(needlepath)
    with open(needlepath, "r") as needlefh:
        needlejson = json.load(needlefh)
    if any(tag in testliterals for tag in needlejson["tags"]):
        continue
    unused.append(needlepath)

# reverse check, for images without a needle file
imgpaths = glob.glob(f"{NEEDLEPATH}/**/*.png", recursive=True)
for imgpath in imgpaths:
    needlepath = imgpath.replace(".png", ".json")
    if not os.path.exists(needlepath):
        noneedle.append(imgpath)

if unused:
    ret += 1
    print("Unused needle(s) found!")
    for needle in unused:
        print(needle)

if noimg:
    ret += 2
    print("Needle(s) without image(s) found!")
    for needle in noimg:
        print(needle)

if noneedle:
    ret += 4
    print("Image(s) without needle(s) found!")
    for img in noneedle:
        print(img)

sys.exit(ret)
