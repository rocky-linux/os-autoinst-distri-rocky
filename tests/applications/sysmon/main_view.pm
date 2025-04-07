use base "installedtest";
use strict;
use testapi;
use utils;

# This script tests that users can switch between the three main regimes.

sub run {
    # wait for the restore to settle down
    wait_still_screen 3;
    assert_and_click("sysmon_fsystems_button");
    assert_screen("sysmon_fsystems_shown");

    assert_and_click("sysmon_processes_button");
    assert_screen("sysmon_processes_shown");

    assert_and_click("sysmon_resources_button");
    assert_screen("sysmon_resources_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;


