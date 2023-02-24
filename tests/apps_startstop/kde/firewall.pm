use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Firewall starts.

sub run {
    my $self = shift;

    # Start the application
    menu_launch_type 'firewall';
    sleep 5;
    # Firewall requires password to be entered and confirmed to start.
    # View password
    assert_screen "auth_required";
    my $password = get_var('ROOT_PASSWORD', 'weakpassword');
    type_very_safely $password;
    send_key 'ret';
    sleep 5;

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
