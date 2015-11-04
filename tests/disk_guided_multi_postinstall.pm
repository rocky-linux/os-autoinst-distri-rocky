use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that second disk is intact
    validate_script_output 'mount /dev/sdb1 /mnt; echo $?', sub { $_ =~ m/0/ };
    validate_script_output 'cat /mnt/testfile', sub { $_ =~ m/Hello, world!/ };
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
