use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Boxes starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('apps_menu_boxes');
    # We get tutorial on F32+, directly to main UI on F<32; we can
    # drop the 'direct to main UI' path once F32 is stable
    assert_screen ['apps_boxes_tutorial', 'apps_run_boxes'];
    if (match_has_tag 'apps_boxes_tutorial') {
        # Let us get rid of the Tutorial window.
        send_key 'esc';
        assert_screen 'apps_run_boxes';
    }

    # Register application
    register_application("gnome-boxes");
    # Close the application
    quit_with_shortcut();
    
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
