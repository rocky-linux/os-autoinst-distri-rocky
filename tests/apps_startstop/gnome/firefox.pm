use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks whether Firefox starts when clicking the icon
# in the activity menu. It does not test any other functionality.

sub run {
    my $self = shift;
    # Start the application
    start_with_launcher('apps_menu_firefox');
    # check that the application is running; this needle is from
    # needles/firefox, it already existed before the 'apps' tests
    # were created
    assert_screen 'firefox';
    # Close the application, but since Firefox needs special handling
    # we are not using the common routine, but deal with this individually instead
    assert_and_click 'apps_stop';
    wait_still_screen 2;
    # deal with warning screen
    if (check_screen("firefox_close_tabs", 1)) {
        click_lastmatch;
    }
    wait_still_screen 2;
    # Register application
    register_application("firefox");
    # check that the application has stopped
    assert_screen 'workspace';
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
