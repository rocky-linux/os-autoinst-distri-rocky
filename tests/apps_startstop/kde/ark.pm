use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Ark starts.

sub run {
    my $self = shift;
    # Start the application with command
    menu_launch_type 'ark';
    # Check that it is started
    assert_screen 'ark_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
