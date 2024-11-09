use base "installedtest";
use strict;
use testapi;
use utils;

# I as a user want to be able use the menu to enter further functions.

sub run {
    my $self = shift;

    # Use the menu to see the shortcuts
    assert_and_click("gnome_burger_menu");
    assert_and_click("clocks_menu_shortcuts");
    assert_screen("clocks_shortcuts_shown");
}

sub test_flags {
    # Rollback after test is over.
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
