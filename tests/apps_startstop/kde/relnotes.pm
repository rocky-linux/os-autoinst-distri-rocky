use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Release Notes starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('relnotes_launch','menu_applications','menu_system');
    # Check that it is started
    assert_screen 'relnotes_runs';
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
