use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    assert_screen "user_console", 300;
    type_string "sudo su\n";
    assert_script_run "coreos-installer install /dev/vda --ignition-url https://www.happyassassin.net/temp/openqa.ign", 600;
    type_string "reboot\n";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
