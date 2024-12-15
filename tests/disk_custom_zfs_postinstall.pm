use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    assert_screen "root_console";
    # check that xfs is used on root partition
    assert_script_run "mount | grep 'on / type xfs'";
    script_run "dnf config-manager --set-enabled crb",300;
    script_run "dnf update --refresh -y",300;
    type_safely "reboot\n";
    boot_to_login_screen;
    # This time, need to login manually.
    console_login(user => "root", password => get_var("ROOT_PASSWORD"));
    sleep 2;
    script_run "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm",300;
    # OpenZFS repo config
    script_run "dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3.el9.noarch.rpm",300;
    # zfs cli utilities
    # For test version, use --enablerepo=zfs-testing
    script_run "dnf install -y zfs",720;
    script_run 'mokutil --sb-state';
    script_run "modprobe zfs";
    script_run "zpool list";
    # DEBUG
    script_run "rpm -qi zfs-2.1.16-1.el9.x86_64";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
