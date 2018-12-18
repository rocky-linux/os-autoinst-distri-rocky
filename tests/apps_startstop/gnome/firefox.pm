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
    # check that the applicatin is running
    assert_screen 'apps_run_firefox';
    # Close the application, but since Firefox needs special handling
    # we are not using the common routine, but deal with this individually instead
    send_key 'alt-f4';
    # deal with warning screen
    assert_and_click 'apps_run_firefox_stop';
    wait_still_screen 2;
    # check that the application has stopped
    assert_screen 'workspace';
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
