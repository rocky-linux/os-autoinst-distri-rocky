use base "installedtest";
use strict;
use tapnet;
use testapi;
use utils;

sub run {
    my $self = shift;
    boot_to_login_screen(timeout => 300);
    $self->root_console(tty=>3);
    setup_tap_static('172.16.2.115', 'vnc002.test.openqa.fedoraproject.org');
    # test test: check if we can see the server
    assert_script_run "ping -c 2 172.16.2.114";
    # FIXME https://pagure.io/fedora-workstation/issue/231 - Boxes
    # dropped VNC functionality, no default replacement yet
    assert_script_run "dnf -y install vinagre";
    desktop_vt;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
