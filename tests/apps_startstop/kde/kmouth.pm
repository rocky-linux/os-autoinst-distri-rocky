use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Kmouth starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('kmouth_launch','menu_applications','menu_utilities');
    # Deal with the welcome screens
    while (check_screen('kde_next', '1')){
        assert_and_click 'kde_next';
    }
    # Settings close
    assert_and_click 'kde_finish';
    wait_still_screen 2;
    # Check that it is started
    assert_screen 'kmouth_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
