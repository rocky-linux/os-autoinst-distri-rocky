use base "installedtest";
use strict;
use testapi;
use utils;
use disks;

# This script will prepare a disk image with the size of
# 1 GB and will add two partitions to it. This will serve as
# a milestone for other follow-up tests.
#

# This script will test if Disks can create new partitions
# in an empty disk.

sub run {
    my $self = shift;

    # Switch to the console and perform some pre-settings.
    # Switch to the console
    $self->root_console(tty => 3);
    # Create a disk image in the home folder. We have decided
    # to use truncate to be able to create bigger partitions
    # that would not require as much space on the disk when
    # empty.
    script_run("truncate -s 1G /root/disk.img");
    # Connect the created partition to the system as a loop device
    # using losetup which will make it accessible to the Disks application
    # later.
    script_run("losetup -P -f --show /root/disk.img");

    # Go back to graphics.
    desktop_vt();
    # Set the update notification_timestamp
    set_update_notification_timestamp();

    menu_launch_type("disks");
    wait_still_screen(3);

    # Make it fill the entire window.
    send_key("super-up");
    wait_still_screen(2);
    assert_screen("apps_run_disks");

    # Click on the listed icon of the new loop device.
    assert_and_click("disks_diskloop_listed");
    # Check that the file has been correctly attached.
    assert_screen("disks_diskloop_status");

    # Format the entire disk with a GPT.
    wipe_disk();

    # Add partitions.
    add_partitions();
}

sub test_flags {
    # If this test fails, there is no need to continue.
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:


