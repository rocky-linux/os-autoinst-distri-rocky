use base "installedtest";
use strict;
use testapi;
use utils;

# This script starts the Calculator and stores an image.

sub run {
    my $self = shift;
    # Set update notification timestamp
    set_update_notification_timestamp();
    # Run the application
    menu_launch_type("Calculator");
    assert_screen("apps_run_calculator");
    # wait for system to settle before snapshotting
    sleep 10;
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:

