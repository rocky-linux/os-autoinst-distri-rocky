use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Calligra Stage starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('cstage_launch','menu_applications','menu_office');
    # Check that it is started
    assert_screen 'cstage_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
