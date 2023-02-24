use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;

    boot_to_login_screen(timeout => 300);
    $self->root_console(tty => 3);
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}
1;
# vim: set sw=4 et:
