use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests that Evince can display the Help pages.

sub run {
    my $self = shift;

    # Open menu with Burger icon.
    assert_and_click("gnome_burger_menu", button => "left", timeout => 30);
    wait_still_screen 2;

    # Select the Help item in the menu.
    assert_and_click("evince_menu_help", button => "left", timeout => 30);
    wait_still_screen 2;

    # Check that Help has been shown.
    assert_screen("evince_help_shown", timeout => 30);
}

sub test_flags {
    return {always_rollback => 1};
}

1;
