use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that K3B starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('k3b_launch','menu_applications','menu_multimedia');
    # Get rid of no burner warning
    assert_and_click 'k3b_burner_warning';
    # Check that it is started
    assert_screen 'k3b_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
