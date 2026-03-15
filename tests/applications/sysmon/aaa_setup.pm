use base "installedtest";
use strict;
use testapi;
use utils;

# This script opens the System Monitor application and saves the milestone
# to make it ready for further testing.

sub run {
    my $self = shift;

    # Set the update notification timestamp
    set_update_notification_timestamp();

    # Start the Application
    menu_launch_type("system_monitor", checkstart => 1, maximize => 1);
}

sub test_flags {
    # If this test fails, there is no need to continue.
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
