use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that xfs is used on root partition
    assert_script_run "mount | grep 'on / type xfs'";
    script_run "dnf config-manager --set-enabled crb",300;
    script_run "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm",300;
    script_run "dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3.el9.noarch.rpm",300;
    script_run "dnf install -y zfs",300;
    script_run "modprobe zfs";
    script_run "zpool list";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
