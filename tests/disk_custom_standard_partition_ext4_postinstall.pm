use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    unless (check_screen "root_console", 0) {
        $self->root_console(tty=>4);
    }
    assert_screen "root_console";
    my $count = 4;
    my $devroot = 'vda1';
    my $devswap = 'vda2';
    my $devboot = 'vda3';
    if (get_var('OFW') || get_var('UEFI')) {
        $count = 5; # extra boot partition (PreP or ESP)
        $devroot = 'vda2';
        $devswap = 'vda3';
        $devboot = 'vda4';
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
