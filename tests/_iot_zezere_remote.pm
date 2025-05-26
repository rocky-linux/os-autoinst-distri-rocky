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
    # allow for UI to stabilize
    wait_still_screen 10;
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
    # time before the provision request goes through is kinda hard to
    # predict, so we'll just try over and over for up to 10 minutes
    # and bail as soon as it works
    assert_script_run 'until ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@172.16.2.119 touch /tmp/zezerekeyfile; do sleep 10; done', 600;
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
