use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Weather starts.

sub run {
    my $self = shift;
    # start the application
    start_with_launcher('apps_menu_weather');
    # give access rights if asked
    if (check_screen('apps_run_access', 1)) {
        assert_and_click 'apps_run_access';
    }
    wait_still_screen 2;
    assert_screen 'apps_run_weather';
    # Register application
    register_application("gnome-weather");
    # close the application
    quit_with_shortcut();

}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
