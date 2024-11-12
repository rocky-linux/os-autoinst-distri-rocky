use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will test if Disks can format an empty
# partition.

sub run {
    # Select the test loop disk.
    assert_and_click("disks_loopdisk_listed");

    # Format partition
    format_partition("one", "swap", "backup");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

