use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will test if Disks can edit the filesystem name.

sub run {
    # Click on the test disk to select it.
    assert_and_click("disks_loopdisk_listed");
    # Edit the filesystem name.
    edit_filesystem("one", "renamed");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

