use base "basetest";
use strict;
use testapi;

sub run {
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    # Begin installation
    assert_and_click "anaconda_main_hub_begin_installation";

    # Set root password
    assert_and_click "anaconda_install_root_password";
    type_string "fedora";
    send_key "tab";
    type_string "fedora";
    assert_and_click "anaconda_spoke_done";
    # weak password - click "done" once again"
    assert_and_click "anaconda_spoke_done";

    # Set user details
    assert_and_click "anaconda_install_user_creation";
    type_string "test";
    send_key "tab";
    send_key "tab";
    send_key "tab";
    send_key "tab";
    type_string "fedora";
    send_key "tab";
    type_string "fedora";
    assert_and_click "anaconda_install_user_creation_make_admin";
    assert_and_click "anaconda_spoke_done";
    # weak password - click "done" once again"
    assert_and_click "anaconda_spoke_done";

    # Wait for install to end
    assert_screen "anaconda_install_done", 1800;
    assert_and_click "anaconda_install_finish";
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
