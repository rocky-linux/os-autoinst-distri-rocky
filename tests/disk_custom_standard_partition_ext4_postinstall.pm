use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that there are two partitions 
    validate_script_output 'fdisk -l | grep /dev/vda | wc -l', sub { $_ =~ m/3/ };
    # check that vda2 is a boot partition and that the fs is ext4
    validate_script_output 'mount | grep /dev/vda2', sub { $_ =~ m/on \/boot type ext4/ };
    # check that vda1 is a root partition and that the fs is ext4
    validate_script_output 'mount | grep /dev/vda1', sub { $_ =~ m/on \/ type ext4/ };
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
