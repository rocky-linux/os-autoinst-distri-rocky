use base "basetest";
use strict;
use testapi;

sub run {
    assert_screen "boot_enter_passphrase", 300; #
    type_string get_var("ENCRYPT_PASSWORD");
    send_key "ret";
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
