use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Fedora Media Writer starts.

sub run {
    my $self = shift;

    # Start the application
    menu_launch_type 'partition editor';
    wait_still_screen 2;
    # Provide root password to run the application
    type_very_safely(get_var("ROOT_PASSWORD", "weakpassword"));
    send_key 'ret';
    wait_still_screen 2;
    # Check that it is started
    assert_screen 'kparted_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
