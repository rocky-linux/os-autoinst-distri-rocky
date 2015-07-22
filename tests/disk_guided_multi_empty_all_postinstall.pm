use base "basetest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    
    # when two disks are selected in installation, LVM is used
    type_string "reset; pvdisplay";
    send_key "ret";
    assert_screen "console_two_disks_mounted_lvm";
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
