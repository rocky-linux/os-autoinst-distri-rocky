use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Clocks starts.

sub run {
    my $self = shift;
    # Start the application
    start_with_launcher('apps_menu_clocks');
    # give access rights if asked
    if (check_screen('apps_run_access', 1)) {
        assert_and_click 'apps_run_access';
    }
    assert_screen 'apps_run_clocks';
    # Register application
    register_application("gnome-clocks");
    # close the application
    quit_with_shortcut();

}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
