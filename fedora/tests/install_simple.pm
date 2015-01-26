use base "basetest";
use strict;
use testapi;

sub run {
    # Wait for bootloader to appear

    assert_screen "bootloader_".get_var("FLAVOR"), 30;

    # Skip the media check
    send_key "up";
    send_key "ret";
    # Select install language
    assert_screen "anaconda_select_install_lang", 300;
    type_string "english";
    assert_and_click "anaconda_select_install_lang_english_filtered";
    assert_screen "anaconda_select_install_lang_english_selected", 3;
    assert_and_click "anaconda_select_install_lang_continue";

    # Anaconda hub
    assert_screen "anaconda_main_hub_".get_var("FLAVOR"), 300; #

    # Default install destination (hdd should be empty for new KVM machine)
    assert_and_click "anaconda_main_hub_install_destination";
    assert_and_click "anaconda_spoke_done";

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

    # Reboot and wait for the text login
    assert_screen "text_console_login", 300; 
  
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { important => 1 };
}

1;

# vim: set sw=4 et:
