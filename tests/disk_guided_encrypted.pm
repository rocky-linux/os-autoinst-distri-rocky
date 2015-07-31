use base "anacondalog";
use strict;
use testapi;

sub run {
    my $self = shift;
    # Anaconda hub
    # Go to INSTALLATION DESTINATION and ensure one disk is selected.
    $self->select_disks();
    assert_and_click "anaconda_install_destination_encrypt_data";
    assert_and_click "anaconda_spoke_done";

    wait_idle 5;
    type_string get_var("ENCRYPT_PASSWORD");
    send_key "tab";
    type_string get_var("ENCRYPT_PASSWORD");

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
