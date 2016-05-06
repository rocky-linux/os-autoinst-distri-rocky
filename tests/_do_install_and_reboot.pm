use base "anacondatest";
use strict;
use testapi;

sub run {
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    # Begin installation
    # Sometimes, the 'slide in from the top' animation messes with
    # this - by the time we click the button isn't where it was any
    # more. So wait a sec just in case.
    sleep 1;
    assert_and_click "anaconda_main_hub_begin_installation";

    # Set root password
    my $root_password = get_var("ROOT_PASSWORD") || "weakpassword";
    assert_and_click "anaconda_install_root_password";
    assert_screen "anaconda_install_root_password_screen";
    type_string $root_password;
    send_key "tab";
    type_string $root_password;
    assert_and_click "anaconda_spoke_done";
    if (check_screen "anaconda_install_password_dictionary_error", 10) {
            assert_and_click "anaconda_spoke_done";
    }

    # Set user details
    sleep 1;
    my $user_login = get_var("USER_LOGIN") || "test";
    my $user_password = get_var("USER_PASSWORD") || "weakpassword";
    assert_and_click "anaconda_install_user_creation";
    assert_screen "anaconda_install_user_creation_screen";
    type_string $user_login;
    assert_and_click "anaconda_user_creation_password_input";
    type_string $user_password;
    send_key "tab";
    type_string $user_password;
    assert_and_click "anaconda_install_user_creation_make_admin";
    assert_and_click "anaconda_spoke_done";
    # handle 'weak password' due to dictionary error: WORKAROUND
    if (check_screen "anaconda_install_password_dictionary_error", 10) {
            assert_and_click "anaconda_spoke_done";
    }

    # Check username (and hence keyboard layout) if non-English
    if (get_var('LANGUAGE')) {
        assert_screen "anaconda_install_user_created";
    }

    # Wait for install to end. Give Rawhide a bit longer, in case
    # we're on a debug kernel, debug kernel installs are really slow.
    my $timeout = 1800;
    if (lc(get_var('VERSION')) eq "rawhide") {
        $timeout = 2400;
    }
    assert_screen "anaconda_install_done", '', $timeout;
    # wait for transition to complete so we don't click in the sidebar
    wait_still_screen 3;
    assert_and_click "anaconda_install_done";
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
