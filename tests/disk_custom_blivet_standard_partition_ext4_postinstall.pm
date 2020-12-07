use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    my $count = 3;
    my $devroot = 'vda2';
    my $devboot = 'vda1';
    if (get_var('OFW') || get_var('UEFI')) {
        $count = 4; # extra boot partition (PreP or ESP)
        $devroot = 'vda3';
        $devboot = 'vda2';
    }
    # check number of partitions
    script_run 'fdisk -l | grep /dev/vda'; # debug
    validate_script_output 'fdisk -l | grep /dev/vda | wc -l', sub { $_ =~ m/$count/ };
    # check mounted partitions are ext4 fs
    script_run 'mount | grep /dev/vda'; # debug
    validate_script_output "mount | grep /dev/$devboot", sub { $_ =~ m/on \/boot type ext4/ };
    validate_script_output "mount | grep /dev/$devroot", sub { $_ =~ m/on \/ type ext4/ };
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
