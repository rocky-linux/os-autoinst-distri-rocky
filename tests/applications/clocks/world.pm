use base "installedtest";
use strict;
use testapi;
use utils;

# I as a user want to be able to add a new city in the World clock.

sub run {
    my $self = shift;

    # Click on the World button.
    assert_and_click("clocks_button_world");

    # Add a new location using the addition icon
    assert_and_click("gnome_add_button_plus");
    wait_still_screen(2);
    type_very_safely("Bratislava");
    assert_and_click("gnome_city_button_bratislava");
    assert_and_click("gnome_add_button");
    wait_still_screen(2);
    diag("CLOCKS: Added the new city.");
    # View city details
    assert_and_click("clocks_city_added_bratislava");
    assert_screen("clocks_city_details");
    diag("CLOCKS: Details shown.");

    # Return back to overview
    assert_and_click("clocks_button_back");
    assert_screen("clocks_city_added_bratislava");

    # Add a new location using the keyboard shortcut
    send_key("ctrl-n");
    wait_still_screen(2);
    type_very_safely("Reykjav");
    assert_and_click("gnome_city_button_reykjavik");
    assert_and_click("gnome_add_button_blue");
    assert_screen("clocks_city_added_reykjavik");

    # Click onto the Delete button to remove the listed cities.
    # While there are cities to be removed, remove them.
    while (check_screen("gnome_button_cross_remove", 3)) {
        click_lastmatch();
        mouse_hide;
    }
    # If the cities are still visible, then die.
    if (check_screen("clocks_city_added_bratislava")) {
        die("The city Bratislava should have been removed, but it is still visible on the screen.");
    }
    if (check_screen("clocks_city_added_reykjavik")) {
        die("The city Reykjavik should have been removed, but it is still visible on the screen.");
    }
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
