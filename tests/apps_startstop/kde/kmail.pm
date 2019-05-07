use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Kmail starts.

sub run {
    my $self = shift;
    
    # Start the application
    menu_launch_type 'kmail';
    # Enable unified mailboxes, if they appear
    if (check_screen("enable_unified_mailboxes", 1)) {
        assert_and_click "enable_unified_mailboxes";
    }
    # Cancel Kmail data wizard
    assert_and_click 'kmail_cancel_data';
    if (check_screen("kmail_cancel_data", 1)) {
        assert_and_click "kmail_cancel_data";
    }
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
