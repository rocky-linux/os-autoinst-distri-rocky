use base "installedtest";
use strict;
use testapi;
use utils;

# This script will start the Gnome Weather application and save
# the image for all subsequent tests.

sub run {
    my $self = shift;

    # Open the Menu
    assert_and_click("gnome_burger_menu");
    assert_and_click("weather_menu_about");
    assert_screen("weather_about_shown");
    # Change to Credits
    assert_and_click("gnome_button_credits");
    assert_screen("weather_credits_shown");
}

sub test_flags {
    # If this test fails, there is no need to continue.
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:

