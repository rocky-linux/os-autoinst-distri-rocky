use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that User handling app starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('users_launch', 'menu_applications','menu_administration');
    # The application requires password to be entered and confirmed to start.
    type_very_safely(get_var('ROOT_PASSWORD','weakpassword'));
    send_key 'ret';
    # Check that it is started
    assert_screen 'users_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
