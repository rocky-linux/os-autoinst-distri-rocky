use base "installedtest";
use strict;
use testapi;
use utils;

# This test tests that Settings starts
#
sub run {
    my $self = shift;
    # start the settings application
    send_key 'alt-f1';
    type_very_safely 'settings';
    send_key 'ret';

    # select Background menu item
    assert_and_click 'apps_settings_menu_background';
    wait_still_screen 5;

    # close the application
    send_key 'alt-f4';
    wait_still_screen 5;

    # check that the screen really is black
    assert_screen 'workspace';
    # Register application
    register_application("gnome-control-center");

}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
