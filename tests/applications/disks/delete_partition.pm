use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will test if Disks can delete a partition
# and add a new partition instead.

sub run {
    # Select the test disk.
    assert_and_click("disks_loopdisk_listed");
    # Delete the second partition.
    delete_partition("two");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

