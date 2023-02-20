use base "anacondatest";
use strict;
use testapi;
use anaconda;

sub run {
    my $self = shift;
    # iscsi config hash
    my %iscsi;
    $iscsi{'iqn.2016-06.local.domain:support.target1'} = ['172.16.2.110', 'test', 'weakpassword'];
    # Anaconda hub
    # Go to INSTALLATION DESTINATION and ensure one regular disk
    # and the iscsi target are selected.
    select_disks(iscsi => \%iscsi);
    assert_and_click "anaconda_spoke_done";
    # now we're at custom part. let's use standard partitioning for
    # simplicity
    custom_scheme_select("standard");
    # Do 'automatic' partition creation
    assert_and_click "anaconda_part_automatic";
    # Make sure / is on the iSCSI target (which appears as sda)
    custom_change_device("root", "sda");
    assert_and_click "anaconda_spoke_done";
    assert_and_click "anaconda_part_accept_changes";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
