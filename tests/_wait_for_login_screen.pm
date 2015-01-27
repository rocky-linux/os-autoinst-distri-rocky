use base "basetest";
use strict;
use testapi;

sub run {

    # If KICKSTART is set, then the wait_time needs to
    #  consider the install time
    my $wait_time = get_var("KICKSTART") ? 600 : 300;

    # Reboot and wait for the text login
    assert_screen "clean_install_login", $wait_time;

    if (get_var("CHECK_LOGIN"))
    {
        if (get_var("FLAVOR") eq "server")
        {
            type_string get_var("USER_LOGIN");
            send_key "ret";
            type_string get_var("USER_PASSWORD");
            send_key "ret";
            assert_screen "user_logged_in", 10;

            if (get_var("ROOT_PASSWORD"))
            {
                type_string "su -";
                send_key "ret";
                assert_screen "console_password_required", 10;
                type_string get_var("ROOT_PASSWORD");
                send_key "ret";
                assert_screen "root_logged_in", 10;
            }
        }
    }

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
