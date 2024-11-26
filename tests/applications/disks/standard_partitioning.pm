use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will test if Disks can delete all partitions and
# create three partitions for Standard partitioning, a small boot
# partition, a bigger root partition, and a home partition that
# takes the rest of the space. All partitions will be formatted
# as ext4.

sub run {
    # Select the test loop disk.
    assert_and_click("disks_loopdisk_listed");

    # Remove partitions
    wipe_disk();

    # Create the partitions (they are formatted as ext4)
    create_partition("boot", "200");
    assert_and_click("disks_free_space");
    create_partition("root", "300");
    assert_and_click("disks_free_space");
    create_partition("home", "full");

    # Mount the partitions
    mount_partition("one");
    mount_partition("two");
    mount_partition("three");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

