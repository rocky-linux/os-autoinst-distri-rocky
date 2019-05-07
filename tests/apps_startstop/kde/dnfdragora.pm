use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that DNFDragora starts.

sub run {
    my $self = shift;
    
    # Start the application
    menu_launch_type 'dnfdragora';
    # Check that it is started
    assert_screen 'dnfdragora_runs';
    sleep 60;
    wait_still_screen 5;
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
