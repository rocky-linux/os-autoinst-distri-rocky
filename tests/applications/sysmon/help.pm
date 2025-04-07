use base "installedtest";
use strict;
use testapi;
use utils;

sub run {

    # Open the Menu and click on Help entry.
    assert_and_click("gnome_burger_menu");
    assert_and_click("sysmon_menu_help");

    # Check that Shortcuts dialogue is shown.
    assert_screen("sysmon_help_shown");

    assert_and_click("sysmon_help_processor");
    assert_and_click("sysmon_help_monitoring");
    assert_and_click("sysmon_help_use_maps");
    assert_and_click("sysmon_help_swap");
    assert_screen("sysmon_help_swap_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

