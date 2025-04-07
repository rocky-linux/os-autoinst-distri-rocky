use base "installedtest";
use strict;
use testapi;
use utils;

# This test will test the Tour application.

sub run {
    my $self = shift;

    console_login();
    desktop_vt();

    # Start the Application
    menu_launch_type("tour");

    assert_and_click("tour_start");

    assert_screen("tour_overview");
    assert_and_click("tour_next");

    assert_screen("tour_arrange_grid");
    assert_and_click("tour_next");

    assert_screen("tour_workspaces");
    assert_and_click("tour_next");

    assert_screen("tour_updown");
    assert_and_click("tour_next");

    assert_screen("tour_leftright");
    assert_and_click("tour_next");

    assert_and_click("tour_done");
}

sub test_flags {
    # If this test fails, there is no need to continue.
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
