use base "basetest";
use strict;
use testapi;

sub run {
    assert_screen "root_logged_in";
    type_string 'reset; mount /dev/sdb1 /mnt; echo $?'; # if you use doublequotes, $? gets replaced by Perl with last error code
    send_key "ret";
    assert_screen "console_command_success";
    type_string 'reset; cat /mnt/testfile';
    send_key "ret";
    assert_screen "provided_disk_intact";
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
