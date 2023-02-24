use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Calendar starts.

sub run {
    my $self = shift;

    # Start the application
    start_with_launcher('apps_menu_calendar');

    # give access to location if the vm asks for it
    if (check_screen('apps_run_access', 1)) {
        assert_and_click 'apps_run_access';
    }
    wait_still_screen 2;
    assert_screen 'apps_run_calendar';
    # Register application
    register_application("gnome-calendar");
    # close the application
    quit_with_shortcut();

}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
