use base "installedtest";
use strict;
use testapi;
use utils;

# This test will test the Tour application.

sub run {
    my $self = shift;

    # Start the Application
    menu_launch_type("tour");

    # Rocky 10+ tour opens without a 'Start' or 'Close' button but with
    # a highlighted next button which will start the tour. The first
    # highlighted right arrow should be captured as tour_start the following
    # un-highlighted right arrow should be captured at tour_next.
    # At the end of the test there is no 'Done' button but the circle-x
    # button should be captured as tour_done.
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
