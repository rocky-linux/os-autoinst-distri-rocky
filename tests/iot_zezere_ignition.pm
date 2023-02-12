use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # wait for the remote test to ssh in and create a file, that
    # tells us we're done
    assert_script_run "until test -f /tmp/zezerekeyfile; do sleep 1; done", 900;
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
