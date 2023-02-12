use base "anacondatest";
use strict;
use testapi;
use utils;

sub run {
    select_rescue_mode;
    # continue
    type_string "1\n";
    assert_screen "rescue_enter_pass", 60;    # it might take time to scan all disks
    type_string get_var("ENCRYPT_PASSWORD", "weakpassword");
    send_key "ret";
    assert_screen "rescue_mounted", 60;    # it also might take time to mount disk
    send_key "ret";

    # check whether disk was mounted
    validate_script_output "mount", sub { $_ =~ m/\/mnt\/sysimage/ };
    # try to access home in chroot
    assert_script_run "chroot /mnt/sysimage ls -la /home/test";
    # try to write and read a file
    assert_script_run "chroot /mnt/sysimage /bin/bash -c 'echo Hello, world > /tmp/openqa_test'";
    validate_script_output "chroot /mnt/sysimage cat /tmp/openqa_test", sub { $_ =~ m/Hello, world/ };
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
