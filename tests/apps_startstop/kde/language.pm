use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Language starts.

sub run {
    my $self = shift;
    
    # Start the application
    menu_launch_type 'language';
    # Deal with confirmation window
    assert_screen "auth_required";
    my $password = get_var('USER_PASSWORD', 'weakpassword');
    type_very_safely $password;
    send_key 'ret';

    # Check that it is started
    assert_screen 'language_runs';
    wait_still_screen 2;
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
