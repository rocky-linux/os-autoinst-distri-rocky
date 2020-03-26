use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Konqueror starts.

sub run {
    my $self = shift;
    
    # Start the application
    menu_launch_type 'konqueror';
    # Confirm the Locations dialog if it is present
    if (check_screen "konqueror_locations") {
        assert_and_click "kde_ok";
    }
    # Check that Konqueror has started
    assert_screen 'konqueror_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
