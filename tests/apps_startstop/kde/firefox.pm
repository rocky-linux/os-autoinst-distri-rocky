use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Firefox starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('firefox_launch','menu_applications','menu_internet');
    # Check that it is started
    assert_screen 'firefox_runs';
    # Close the application
    send_key 'alt-f4';
    wait_still_screen 2;
    assert_and_click 'firefox_close_tabs';
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
