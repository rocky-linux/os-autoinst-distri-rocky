use base "installedtest";
use strict;
use tapnet;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->root_console(tty=>3);
    setup_tap_static('10.0.2.115', 'vnc002.domain.local');
    # test test: check if we can see the server
    assert_script_run "ping -c 2 10.0.2.114";
    desktop_vt;
    menu_launch_type('boxes');
    assert_and_click('boxes_new_connection');
    assert_and_click('boxes_remote');
    type_very_safely("vnc://10.0.2.114:5901\n");
    assert_and_click('boxes_allow_inhibit');
    assert_and_click('boxes_fullscreen');
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
