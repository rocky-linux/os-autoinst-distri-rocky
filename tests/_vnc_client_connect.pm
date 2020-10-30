use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    menu_launch_type('boxes');
    assert_screen ['apps_boxes_tutorial', 'boxes_new_connection'];
    if (match_has_tag 'apps_boxes_tutorial') {
        # Let us get rid of the Tutorial window.
        send_key 'esc';
    }
    assert_and_click('boxes_new_connection');
    assert_and_click('boxes_remote');
    type_very_safely("vnc://172.16.2.114:5901\n");
    assert_and_click('boxes_allow_inhibit');
    assert_and_click('boxes_fullscreen');
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
