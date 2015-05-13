use base "fedoralog";
use strict;
use testapi;

sub boot_and_login {
    wait_still_screen 10;

    my $password = get_var("ROOT_PASSWORD", "weakpassword");

    send_key "ctrl-alt-f3";
    assert_screen "text_console_login", 20;
    type_string "root";
    send_key "ret";
    assert_screen "console_password_required", 10;
    type_string $password;
    send_key "ret";
    assert_screen "root_logged_in", 10;
}

sub run {
    boot_and_login();

    assert_screen "console_f22_installed";
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
