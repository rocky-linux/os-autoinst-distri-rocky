use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests that Evince displays shortcuts.

sub run {
    my $self = shift;

    # Open the menu
    assert_and_click("gnome_burger_menu", button => "left", timeout => 30);
    wait_still_screen 2;

    # Select the Keyboard Shortcuts item
    assert_and_click("evince_menu_shortcuts", button => "left", timeout => 30);
    wait_still_screen 2;

    # Check that Shortcuts has been shown
    assert_screen("evince_shortcuts_shown");

    # Click on number 2 to arrive to the second page
    assert_and_click("evince_shortcuts_second", button => "left", timeout => 30);

    # Check that Shortcuts 2 has been shown
    assert_screen("evince_shortcuts_second_shown");

    # Click on number 3 to arrive to the second page
    assert_and_click("evince_shortcuts_third", button => "left", timeout => 30);

    # Check that Shortcuts 3 has been shown
    assert_screen("evince_shortcuts_third_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;
