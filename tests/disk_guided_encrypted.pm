use base "anacondatest";
use strict;
use testapi;
use utils;
use anaconda;

sub run {
    my $self = shift;
    # Anaconda hub
    # Go to INSTALLATION DESTINATION and ensure one disk is selected.
    select_disks();

    # check "encrypt data" checkbox
    assert_and_click "anaconda_install_destination_encrypt_data";
    assert_and_click "anaconda_spoke_done";

    # type password for disk encryption
    wait_idle 5;
    if (get_var("SWITCHED_LAYOUT")) {
        desktop_switch_layout "ascii", "anaconda";
    }
    type_safely get_var("ENCRYPT_PASSWORD");
    wait_screen_change { send_key "tab"; };
    type_safely get_var("ENCRYPT_PASSWORD");
    if (get_var("SWITCHED_LAYOUT")) {
        # work around RHBZ #1333984
        desktop_switch_layout "native", "anaconda";
    }

    assert_and_click "anaconda_install_destination_save_passphrase";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

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
