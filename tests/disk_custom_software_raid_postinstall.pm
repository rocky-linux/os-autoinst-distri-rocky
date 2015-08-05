use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that RAID is used
    type_string "reset; cat /proc/mdstat";
    send_key "ret";
    assert_screen "console_raid_used";
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
