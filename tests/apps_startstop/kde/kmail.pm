use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Kmail starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('kmail_launch','menu_applications','menu_internet');
    # Cancel Kmail data wizard
    assert_and_click 'kmail_cancel_data';
    # Check that it is started
    assert_screen 'kmail_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
