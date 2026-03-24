use base "installedtest";
use strict;
use testapi;
use tapnet;
use utils;

sub run {
    my $self = shift;
    my $distri = get_var("DISTRI");
    my $desktop = get_var("DESKTOP");
    my $user_login = get_var("USER_LOGIN");

    my ($ip, $hostname) = split(/ /, get_var("POST_STATIC"));
    $hostname //= 'localhost.localdomain';

    # switch to TTY3 for graphical tests where user login is not blocked
    # NOTE: The choice of TTY3 comes from _console_wait_login test.
    if ($distri eq "rocky" && $desktop eq "gnome" && $user_login ne "false") {
        $self->root_console(tty => 3);
        assert_screen("root_console");
    }

    # set up networking
    setup_tap_static($ip, $hostname);
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
