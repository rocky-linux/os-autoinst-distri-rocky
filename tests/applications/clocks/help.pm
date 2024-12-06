use base "installedtest";
use strict;
use testapi;
use utils;

# I as a user want to be able use the menu to enter further functions.

sub run {
    my $self = shift;

    # Click on the burger menu and display Help.
    assert_and_click("gnome_burger_menu");
    assert_and_click("clocks_menu_help");
    assert_screen("clocks_help_shown");
}

sub test_flags {
    # Rollback after test is over.
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
