use base "installedtest";
use strict;
use lockapi;
use testapi;
use utils;

sub run {
    my $self = shift;
    # set up an ssh key
    type_string "ssh-keygen\n";
    sleep 2;
    # confirm directory
    send_key "ret";
    sleep 2;
    # empty passphrase
    send_key "ret";
    sleep 2;
    # confirm empty passphrase
    send_key "ret";
    my $sshpub = script_output "cat /root/.ssh/id_rsa.pub";
    # launch Firefox
    type_string "startx /usr/bin/firefox -width 1024 -height 768 http://172.16.2.118\n";
    # log in as admin
    assert_screen "zezere_login";
    type_string "admin";
    send_key "tab";
    type_string "weakpassword\n";
    # add our ssh key
    assert_and_click "zezere_ssh_key";
    assert_and_click "zezere_ssh_key_contents";
    type_string "$sshpub";
    send_key "tab";
    send_key "ret";
    # claim the device
    assert_and_click "zezere_claim_unowned";
    assert_and_click "zezere_claim_button";
    # provision it
    assert_and_click "zezere_device_management";
    assert_and_click "zezere_submit_provision";
    assert_and_click "zezere_provision_menu";
    send_key_until_needlematch("zezere_provision_installed", "down", 3, 3);
    assert_and_click "zezere_provision_schedule";
    # exit
    quit_firefox;
    # wait for the provision request to go through
    sleep 30;
    # ssh into iot host and create key file
    assert_script_run 'ssh -o StrictHostKeyChecking=no root@172.16.2.119 touch /tmp/zezerekeyfile';
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
