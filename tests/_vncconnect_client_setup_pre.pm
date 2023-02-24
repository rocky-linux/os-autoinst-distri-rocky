use base "installedtest";
use strict;
use tapnet;
use testapi;
use utils;

sub run {
    my $self = shift;
    boot_to_login_screen(timeout => 300);
    $self->root_console(tty => 3);
    setup_tap_static('172.16.2.117', 'vnc004.test.openqa.fedoraproject.org');
    # install tigervnc (Boxes doesn't do reverse VNC)
    assert_script_run "dnf -y install tigervnc", 180;
    # take down the firewall
    assert_script_run "systemctl stop firewalld";
    desktop_vt;
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
