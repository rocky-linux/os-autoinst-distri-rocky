use base "anacondatest";
use strict;
use testapi;
use anaconda;

sub run {
    my $self = shift;
    # Anaconda hub
    # Go to INSTALLATION DESTINATION and ensure one disk is selected.
    select_disks();
    assert_and_click "anaconda_spoke_done";

    # the only provided disk should be automatically selected and full
    assert_and_click "anaconda_install_destination_reclaim_space_btn";

    assert_and_click "anaconda_install_destination_delete_all_btn";

    assert_and_click "anaconda_install_destination_reclaim_space_btn";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
