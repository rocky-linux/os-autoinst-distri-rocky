use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests that Evince can show Document Properties.

sub run {
    my $self = shift;

    # Open the menu.
    assert_and_click("gnome_burger_menu", button => "left", timeout => 30);
    wait_still_screen 2;

    # Select the Properties item.
    assert_and_click("evince_menu_properties", button => "left", timeout => 30);
    wait_still_screen 2;

    # Check that Properties are shown.
    assert_screen("evince_properties_shown", timeout => 30);
}

sub test_flags {
    return {always_rollback => 1};
}

1;
