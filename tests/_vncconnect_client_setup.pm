use base "installedtest";
use strict;
use lockapi;
use tapnet;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->root_console(tty=>3);
    setup_tap_static('10.0.2.117', 'vnc004.domain.local');
    # install tigervnc (Boxes doesn't do reverse VNC)
    assert_script_run "dnf -y install tigervnc", 180;
    # take down the firewall
    assert_script_run "systemctl stop firewalld";
    desktop_vt;
    menu_launch_type 'terminal';
    wait_still_screen 5;
    type_very_safely "vncviewer -FullScreen -listen\n";
    mutex_create 'vncconnect_client_ready';
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
