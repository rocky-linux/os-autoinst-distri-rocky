use base "anacondatest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # Go to INSTALLATION DESTINATION and ensure two disks are selected.
    $self->select_disks(2);
    # select custom partitioning
    assert_and_click "anaconda_manual_partitioning";
    assert_and_click "anaconda_spoke_done";

    # Manual partitioning spoke should be displayed
    assert_and_click "anaconda_part_automatic";
    $self->custom_change_type("raid");
    assert_and_click "anaconda_spoke_done";
    assert_and_click "anaconda_part_accept_changes";

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
