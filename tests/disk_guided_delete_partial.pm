use base "anacondalog";
use strict;
use testapi;

sub run {
    my $self = shift;
    # Anaconda hub
    # Go to INSTALLATION DESTINATION and ensure one disk is selected.
    $self->select_disks();
    assert_and_click "anaconda_spoke_done";

    # Provided disk should be full
    assert_and_click "anaconda_install_destination_reclaim_space_btn";

    assert_and_click "anaconda_install_destination_reclaim_space_first_partition";

    assert_and_click "anaconda_install_destination_reclaim_space_delete_btn";

    assert_and_click "anaconda_install_destination_reclaim_space_btn";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
