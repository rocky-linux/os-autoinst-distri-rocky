use base "installedtest";
use strict;
use testapi;
use utils;

# This test tests that Settings starts and the it can be used to
# change the desktop settings. 
# This test was originally used to set the virtual machine desktop
# to black to support other tests. This functionality has been taken
# by the Terminal test.
# You can put this test anywhere in the suite without any problems.

sub run {
    my $self = shift;
    # start the settings application
    send_key 'alt-f1';
    type_very_safely 'settings';
    send_key 'ret';
    
    # select Background menu item
    assert_and_click 'apps_settings_menu_background';
    wait_still_screen 5;
    assert_and_click 'apps_settings_choose_background';
    wait_still_screen 5;
    
    # select the Background color menu and move down until black is found, then click it.
    assert_and_click 'apps_settings_choose_color';
    wait_still_screen 5;
    my $black_visible = 0;
    while ($black_visible == 0) {
        send_key 'down';
        if (check_screen('apps_settings_black_visible', 1)) {
            $black_visible = 1;
        }
    }
    assert_and_click 'apps_settings_black_visible';
    wait_still_screen 5;

    # confirm the selection
    assert_and_click 'apps_settings_black_select';
    wait_still_screen 5;

    # close the application
    send_key 'alt-f4';
    wait_still_screen 5;

    # check that the screen really is black
    assert_screen 'workspace';
    
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
