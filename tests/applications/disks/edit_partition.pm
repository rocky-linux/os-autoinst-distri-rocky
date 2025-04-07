use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will test if Disks can edit the partition name.

sub run {
    # Open the menu
    assert_and_click("disks_loopdisk_listed");
    # Change the type of the partition.
    edit_partition("one", "linuxroot", "partroot");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

