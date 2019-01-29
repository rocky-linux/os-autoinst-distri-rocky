use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Kget starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('kget_launch','menu_applications','menu_internet');
    # Enable as default application
    assert_and_click 'kget_enable';
    # Check that it is started
    assert_screen 'kget_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
