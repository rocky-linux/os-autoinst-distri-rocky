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

    # Delete first partition, second should be untouched
    assert_and_click "anaconda_install_destination_reclaim_space_first_partition";

    assert_and_click "anaconda_install_destination_reclaim_space_delete_btn";

    # If this fails with a disabled button, we didn't reclaim enough space to perform installation
    assert_and_click "anaconda_install_destination_reclaim_space_btn";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
