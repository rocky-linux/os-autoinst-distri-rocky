use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Konversation starts.

sub run {
    my $self = shift;
    
    # Start the application
    menu_launch_type 'konversation';
    # Connect to Freenode
    assert_and_click 'konversation_connect';
    # Check that it is started
    assert_screen 'konversation_runs';
    # Close the application
    send_key 'alt-f4';
    wait_still_screen 2;
    assert_and_click 'konversation_confirm_close';
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
