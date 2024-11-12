use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will test if Disks can resize a partition and
# put a new partition after the resized one.

sub run {
    # Select the test loop disk.
    assert_and_click("disks_loopdisk_listed");
    # Resize the second partition
    resize_partition("two", "320");

    # Add a new partition to the remainaing space
    assert_and_click("disks_free_space");

    # Create another partition in the remaining space.
    create_partition("terciavolta", "full");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

