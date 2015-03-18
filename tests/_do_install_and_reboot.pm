use base "anacondalog";
use strict;
use testapi;

sub run {
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    # Begin installation
    assert_and_click "anaconda_main_hub_begin_installation";

    # Set root password
    my $root_password = get_var("ROOT_PASSWORD") || "weakpassword";
    assert_and_click "anaconda_install_root_password";
    type_string $root_password;
    send_key "tab";
    type_string $root_password;
    assert_and_click "anaconda_spoke_done";
    # weak password - click "done" once again"
    #assert_and_click "anaconda_spoke_done";

    # Set user details
    sleep 1;
    my $user_login = get_var("USER_LOGIN") || "test";
    my $user_password = get_var("USER_PASSWORD") || "weakpassword";
    assert_and_click "anaconda_install_user_creation";
    type_string $user_login;
    send_key "tab";
    send_key "tab";
    send_key "tab";
    send_key "tab";
    type_string $user_password;
    send_key "tab";
    type_string $user_password;
    assert_and_click "anaconda_install_user_creation_make_admin";
    assert_and_click "anaconda_spoke_done";
    # weak password - click "done" once again"
    #assert_and_click "anaconda_spoke_done";

    # Wait for install to end
    assert_and_click "anaconda_install_done", '', 1800;
    if (get_var('LIVE')) {
        x11_start_program("reboot");
    }
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
