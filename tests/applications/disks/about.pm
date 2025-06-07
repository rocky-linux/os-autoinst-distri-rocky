use base "installedtest";
use strict;
use testapi;
use utils;

# This script will open the About dialogue and check
# that it works.

sub run {
    # Open the menu
    assert_and_click("gnome_burger_menu");

    # Click on the About item
    assert_and_click("gnome_menu_about");

    # Check that the dialogue is shown.
    assert_screen("disks_about_shown");

    # Click on the Credits button.
    assert_and_click("gnome_button_credits");

    # Check that Credits are shown.
    assert_screen("disks_credits_shown");

    # Dismiss the About window using the Esc key.
    send_key("esc");
}

sub test_flags {
    return {fatal => 0};
}

1;
