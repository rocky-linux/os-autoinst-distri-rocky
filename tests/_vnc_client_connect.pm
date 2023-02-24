use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    menu_launch_type('vinagre');
    assert_and_click('vinagre_new_connection');
    assert_and_click('vinagre_protocol');
    assert_and_click('vinagre_protocol_vnc');
    send_key('tab');
    type_very_safely("172.16.2.114:5901\n");
    # this panel likes to move around so make sure we really hit it
    while (check_screen 'vinagre_enable_shortcuts') {
        assert_and_click('vinagre_enable_shortcuts');
        sleep 2;
    }
    assert_and_click('vinagre_allow_inhibit');
    assert_and_click('vinagre_fullscreen');
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
