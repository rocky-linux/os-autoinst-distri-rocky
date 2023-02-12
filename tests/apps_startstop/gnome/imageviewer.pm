use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Image Viewer starts.

sub run {
    my $self = shift;

    # Start the application
    start_with_launcher('apps_menu_imageviewer', 'apps_menu_utilities');
    # Check that is started
    assert_screen 'apps_run_imageviewer';
    # Register application
    register_application("image-viewer");
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
