use base "installedtest";
use strict;
use lockapi;
use testapi;
use utils;

sub run {
    my $self = shift;
    menu_launch_type 'terminal';
    wait_still_screen 5;
    type_very_safely "vncviewer -FullScreen -listen\n";
    mutex_create 'vncconnect_client_ready';
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
