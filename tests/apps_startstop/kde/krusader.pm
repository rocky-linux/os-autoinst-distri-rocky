use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Krusader starts.

sub run {
    my $self = shift;
    
    # Start the application
    menu_launch_type "krusader";
    # Deal with the welcome screens
    assert_screen ["krusader_welcome", "krusader_settings_close"];
    while (match_has_tag "krusader_welcome") {
        assert_and_click "krusader_welcome";
        assert_screen ["krusader_welcome", "krusader_settings_close"];
    }
    # Settings close
    assert_screen ["krusader_settings_close", "kde_ok"];
    while (match_has_tag "kde_ok") {
        assert_and_click "kde_ok";
        assert_screen ["krusader_settings_close", "kde_ok"]
    }
    
    assert_and_click "krusader_settings_close";
    
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
