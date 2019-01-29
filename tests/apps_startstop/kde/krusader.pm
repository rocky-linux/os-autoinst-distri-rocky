use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Krusader starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('krusader_launch','menu_applications','menu_utilities');
    # Deal with the welcome screens
    while (check_screen('krusader_welcome', '1')){
        assert_and_click 'krusader_welcome';
    }
    # Settings close
    assert_and_click 'krusader_settings_close';
    wait_still_screen 2;
    # Check that it is started
    assert_screen 'krusader_runs';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
