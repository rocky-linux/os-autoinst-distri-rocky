use base "anacondatest";
use strict;
use testapi;
use utils;
use anaconda;

sub run {
    my $self = shift;
    # Go to INSTALLATION DESTINATION and ensure the disk is selected.
    # Because PARTITIONING starts with 'custom_', this will select custom.
    select_disks();
    assert_and_click "anaconda_spoke_done";

    # Manual partitioning spoke should be displayed
    assert_and_click "anaconda_part_automatic";
    # Make / smaller
    send_key_until_needlematch("anaconda_part_mountpoint_selected", "tab", 20);
    # One tab on from 'mount point selected' is 'size'
    send_key "tab";
    type_very_safely "8 GiB";
    assert_and_click "anaconda_part_update_settings";
    wait_still_screen 5;
    # Add swap
    assert_and_click "anaconda_part_add";
    type_very_safely "swap";
    send_key "tab";
    assert_and_click "anaconda_part_add_mountpoint";
    assert_and_click "anaconda_spoke_done";
    assert_and_click "anaconda_part_accept_changes";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300;    #

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
