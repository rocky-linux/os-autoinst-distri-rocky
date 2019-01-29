use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Kontact starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('kontact_launch','menu_applications','menu_office');
    # Get rid of personal data
    assert_and_click 'kontact_provide_data';
    # Check that it is started
    assert_screen 'kontact_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
