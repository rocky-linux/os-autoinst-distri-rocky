use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Gwenview starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('gwenview_launch','menu_applications','menu_graphics');
    # Check that it is started
    assert_screen 'gwenview_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
