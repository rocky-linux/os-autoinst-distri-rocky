use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Infocenter starts.
# It will also check that Infocenter contains the new module
# called plasma-disks.

sub run {
    my $self = shift;

    # Start the application
    menu_launch_type 'info';
    # Check that it is started
    assert_screen 'infocenter_runs';
    # Open the Devices menu item.
    assert_and_click "infocenter_menu_devices";
    # If the disks module is present, open it
    assert_and_click "infocenter_smart_status";
    # Check that a correct screen is displayed.
    assert_screen "infocenter_smart_status_shown";
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
