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

    # select first partition
    assert_and_click "anaconda_install_destination_reclaim_space_first_partition";

    # shrink partition
    assert_and_click "anaconda_install_destination_reclaim_space_shrink_btn";
    assert_and_click "anaconda_install_destination_reclaim_space_shrink_slider";

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
