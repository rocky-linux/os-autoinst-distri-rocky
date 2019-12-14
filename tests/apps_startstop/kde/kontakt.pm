use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Kontact starts.

sub run {
    my $self = shift;
    
    # Start the application
    menu_launch_type 'kontact';
    # Enable unified mailboxes, if they appear
    if (check_screen("enable_unified_mailboxes", 3)) {
        assert_and_click "enable_unified_mailboxes";
    }
    # Get rid of personal data
    assert_and_click 'kontact_provide_data';
    if (check_screen("enable_unified_mailboxes", 3)) {
        assert_and_click "enable_unified_mailboxes";
    }
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
