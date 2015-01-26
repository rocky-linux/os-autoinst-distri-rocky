use base "basetest";
use strict;
use testapi;

sub run {

    # Reboot and wait for the text login
    assert_screen "clean_install_login", 300;

}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { milestone => 1 };
}

1;

# vim: set sw=4 et:
