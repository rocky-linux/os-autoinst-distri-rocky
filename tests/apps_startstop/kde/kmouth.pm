use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Kmouth starts.

sub run {
    my $self = shift;

    # Start the application
    menu_launch_type 'kmouth';
    sleep 2;
    # Deal with the welcome screens
    assert_screen ["kde_next", "kde_finish"];
    while (match_has_tag "kde_next") {
        assert_and_click "kde_next";
        sleep 2;
        assert_screen ["kde_next", "kde_finish"];
    }
    # Settings close
    assert_and_click 'kde_finish';
    wait_still_screen 2;
    # Check that it is started
    assert_screen 'kmouth_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
