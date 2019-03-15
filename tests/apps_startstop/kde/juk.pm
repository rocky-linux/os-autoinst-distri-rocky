use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Juk starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('juk_launch','menu_applications','menu_multimedia');
    # Dismiss a setting window
    assert_and_click 'juk_cancel';
    wait_still_screen 2;
    # Check that it is started
    assert_screen 'juk_runs';
    # Close the application
    send_key 'alt-f4';
    assert_and_click 'juk_confirm';
    
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
