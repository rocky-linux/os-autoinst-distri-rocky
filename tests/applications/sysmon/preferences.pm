use base "installedtest";
use strict;
use testapi;
use utils;

sub run {

    # Open the Menu and click on Preferences entry.
    assert_and_click("gnome_burger_menu");
    assert_and_click("sysmon_menu_preferences");

    # Check that Preferences dialogue is shown.
    assert_screen("sysmon_preferences_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

