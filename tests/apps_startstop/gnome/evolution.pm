use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Evolution starts.

sub run {
    my $self = shift;
    # Start the application
    start_with_launcher('apps_menu_evolution');
    # get rid of the welcome screen
    if ('apps_run_evolution_warning') {
        assert_and_click 'apps_run_evolution_warning';
    }
    assert_and_click 'apps_run_evolution_welcome';
    wait_still_screen 2;
    # Check that is started
    assert_screen 'apps_run_evolution';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
