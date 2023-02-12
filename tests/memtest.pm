use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that MEMTEST can be chosen in the ISO's grub menu.
# The we will see, if such memtest start and progresses to certain
# level.
#

sub run {

    # Let's navigate through the Grub menu and choose the memtest item.
    # We use plenty of sleeps to slower down the process a little bit
    # and to make it visible at the video and for some troubleshooting.
    # We do not want to use any needles here to navigate the menu.
    # Wait for Grub to settle
    sleep 5;
    # Choose "Troubleshooting"
    send_key "down";
    sleep 2;
    send_key "ret";
    sleep 2;
    # Start memtest
    send_key "down";
    sleep 1;
    send_key "down";
    sleep 1;
    send_key "ret";
    # Now Memtest should be running.
    send_key "f1";
    # Assert that the test has reached 10%
    assert_screen "memtest_ten_percent", 120;
    # And that it has progressed to 20%
    assert_screen "memtest_twenty_percent", 120;

    #Then try to select a specific test
    send_key "c";
    sleep 1;
    send_key "1";
    sleep 1;
    send_key "3";
    sleep 1;
    send_key "7";
    sleep 1;
    send_key "ret";
    sleep 1;
    send_key "0";

    #Assert that the test has been completed.
    assert_screen "memtest_seven_completed", 240;
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
