use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # check / is xfs, as it should be on server
    assert_script_run 'findmnt -M / -o FSTYPE | grep xfs';
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
