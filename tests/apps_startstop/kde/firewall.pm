use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Firewall starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('firewall_launch', 'menu_applications','menu_administration');
    # Firewall requires password to be entered and confirmed to start.
    type_very_safely(get_var('ROOT_PASSWORD','weakpassword'));
    send_key 'ret';
    # Check that it is started
    assert_screen 'firewall_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
