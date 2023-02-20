use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $wait_time = 300;
    # if we're running an upgrade, we must wait for the entire upgrade
    # process to run
    $wait_time = 6000 if (get_var("UPGRADE"));
    # decrypt disks during boot
    boot_decrypt($wait_time);
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
