use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    my $count = 4;
    my $devroot = 'vda1';
    my $devboot = 'vda2';
    my $devswap = 'vda3';
    if (get_var('OFW') || get_var('UEFI')) {
        $count = 5; # extra boot partition (PreP or ESP)
        $devroot = 'vda2';
        $devboot = 'vda3';
        $devswap = 'vda4';
    }
    # check number of partitions
    script_run 'fdisk -l | grep /dev/vda'; # debug
    validate_script_output 'fdisk -l | grep /dev/vda | wc -l', sub { $_ =~ m/$count/ };
    # check mounted partitions are ext4 fs
    script_run 'mount | grep /dev/vda'; # debug
    validate_script_output "mount | grep /dev/$devboot", sub { $_ =~ m/on \/boot type ext4/ };
    validate_script_output "mount | grep /dev/$devroot", sub { $_ =~ m/on \/ type ext4/ };
    validate_script_output "swapon --show | grep /dev/$devswap", sub { $_ =~ m/ partition / };
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
