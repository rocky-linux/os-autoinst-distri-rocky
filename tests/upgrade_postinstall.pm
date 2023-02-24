use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # try to login, check whether target release is installed
    $self->root_console(tty => 3);
    check_release(lc(get_var('VERSION')));
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
