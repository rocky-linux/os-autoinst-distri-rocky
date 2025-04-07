use base "installedtest";
use strict;
use testapi;
use utils;

sub run {

    # Open the Menu and click on the About entry.
    assert_and_click("gnome_burger_menu");
    assert_and_click("sysmon_menu_about");

    # Check that About dialogue has started.
    assert_screen("sysmon_about_shown");
    # Click on the Credits button
    assert_and_click("gnome_button_credits");
    # Check that Credits are shown
    assert_screen("sysmon_credits_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;
