use base "anacondatest";
use strict;
use testapi;
use utils;

sub run {
    select_rescue_mode;
    # select rescue shell and expect shell prompt
    type_string "3\n";
    send_key "ret";
    assert_screen "root_console", 5;    # should be shell prompt
    assert_script_run "fdisk -l | head -n20";
    assert_script_run "mkdir -p /hd";
    assert_script_run "mount /dev/vdb1 /hd";
    copy_devcdrom_as_isofile('/hd/fedora_image.iso');
    assert_script_run "umount /hd";
    type_string "exit\n";    # leave rescue mode.
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
