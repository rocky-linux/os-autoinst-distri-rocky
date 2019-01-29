use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Language starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('language_launch', 'menu_applications','menu_administration');
    # Deal with confirmation window
    type_very_safely(get_var('USER_PASSWORD', 'weakpassword'));
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
