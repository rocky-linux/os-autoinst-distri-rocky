use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will test if current partitions can be mounted
# via the Disks application.


sub run {
    my $self = shift;

    # Wipe the entire disk, recreate partitions
    wipe_disk();
    add_partitions();


    # Mount the first partition.
    mount_partition("one");

    # Mount the second partition.
    mount_partition("two");

    # Check in the system that the partitions have been mounted.
    $self->root_console(tty => 3);
    # First partition
    assert_script_run("findmnt /dev/loop0p1");
    # Second partition
    assert_script_run("findmnt /dev/loop0p2");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

