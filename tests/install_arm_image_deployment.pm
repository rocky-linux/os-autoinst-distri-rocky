use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    assert_screen "console_initial_setup", 200;
    # IMHO it's better to use sleeps than to have needle for every text screen
    wait_still_screen 5;

    # Set timezone
    type_string "2\n";
    wait_still_screen 5;
    type_string "1\n"; # Set timezone
    wait_still_screen 5;
    type_string "1\n"; # Europe
    wait_still_screen 5;
    type_string "37\n"; # Prague
    wait_still_screen 7;

    # Set root password
    type_string "4\n";
    wait_still_screen 5;
    type_string get_var("ROOT_PASSWORD") || "weakpassword";
    send_key "ret";
    wait_still_screen 5;
    type_string get_var("ROOT_PASSWORD") || "weakpassword";
    send_key "ret";
    wait_still_screen 7;

    # Create user
    type_string "5\n";
    wait_still_screen 5;
    type_string "1\n"; # create new
    wait_still_screen 5;
    type_string "3\n"; # set username
    wait_still_screen 5;
    type_string get_var("USER_LOGIN", "test");
    send_key "ret";
    wait_still_screen 5;
    type_string "4\n"; # use password
    wait_still_screen 5;
    type_string "5\n"; # set password
    wait_still_screen 5;
    type_string get_var("USER_PASSWORD", "weakpassword");
    send_key "ret";
    wait_still_screen 5;
    type_string get_var("USER_PASSWORD", "weakpassword");
    send_key "ret";
    wait_still_screen 5;
    type_string "6\n"; # make him an administrator
    wait_still_screen 5;
    type_string "c\n";
    wait_still_screen 7;

    assert_screen "console_initial_setup_done", 30;
    type_string "c\n"; # continue
    assert_screen "text_console_login", 60;

    # Try to log in as an user
    console_login(user=>get_var("USER_LOGIN", "test"), password=>get_var("USER_PASSWORD", "weakpassword"));
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
