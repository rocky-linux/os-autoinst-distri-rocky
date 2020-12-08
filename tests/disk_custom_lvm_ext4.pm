use base "anacondatest";
use strict;
use testapi;
use anaconda;

sub run {
    my $self = shift;
    # Go to INSTALLATION DESTINATION and ensure the disk is selected.
    # Because PARTITIONING starts with 'custom_', this will select custom.
    select_disks();
    assert_and_click "anaconda_spoke_done";

    # Manual partitioning spoke should be displayed. Select LVM
    # Partitioning scheme
    custom_scheme_select("lvm");
    # Do 'automatic' partition creation
    assert_and_click "anaconda_part_automatic";
    # Change file system to ext4 on root and boot partitions.
    custom_change_fs("ext4", "boot");
    custom_change_fs("ext4", "root");
    # Confirm changes
    assert_and_click "anaconda_spoke_done";
    assert_and_click "anaconda_part_accept_changes";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
