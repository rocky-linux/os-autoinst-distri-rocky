use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    assert_screen "root_console";
    assert_script_run "dnf config-manager --set-enabled crb",300;
    assert_script_run "dnf update --refresh -y",720;
    type_safely "reboot\n";
    boot_to_login_screen;
    # This time, need to login manually.
    console_login(user => "root", password => get_var("ROOT_PASSWORD"));
    sleep 2;
    assert_screen "root_console";
    assert_script_run "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm",300;
    # OpenZFS repo config
    assert_script_run "dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3.el9.noarch.rpm",300;
    # zfs cli utilities
    # For test version, use --enablerepo=zfs-testing
    assert_script_run "dnf install -y zfs",720;
    script_run 'mokutil --sb-state';
    script_run "modprobe zfs";
    assert_script_run "lsmod | grep zfs";
    assert_script_run "zpool create zfs /dev/vdb /dev/vdc";
    assert_script_run "zpool list";
    assert_script_run "zpool status";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
