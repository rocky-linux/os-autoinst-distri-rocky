use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that DNFDragora starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('dnfdragora_launch', 'menu_applications','menu_administration');
    # Check that it is started
    assert_screen 'dnfdragora_runs';
    sleep 30;
    wait_still_screen 5;
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
