use base "installedtest";
use strict;
use testapi;
use utils;

# This script checks that Gnome Calculator shows help.

sub run {
    my $self = shift;
    # Wait until everything settles.
    sleep 5;
    # Open Help
    send_key("f1");
    wait_still_screen(2);

    # Browse through a couple of links and
    # check they are not empty.
    assert_and_click("calc_help_using_keyboard");
    assert_screen("calc_help_keyboard");
    assert_and_click("calc_help_main_view");
    assert_and_click("calc_help_using_factorial");
    assert_screen("calc_help_factorial");
    assert_and_click("calc_help_main_view");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:

