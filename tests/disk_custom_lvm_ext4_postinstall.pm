use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    unless (check_screen "root_console", 0) {
        $self->root_console(tty => 4);
    }
    assert_screen "root_console";
    my $devboot = 'vda1';

    if (get_var('OFW') || get_var('UEFI')) {
        $devboot = 'vda2';
    }
    # check that lvm is present:
    validate_script_output "lvdisplay | grep 'LV Status'", sub { $_ =~ m/available/ };

    # Check for standard LVM attributes, w - writable, i-inherited, a-active, o-open
    validate_script_output "lvs -o lv_attr", sub { $_ =~ m/wi-ao/ };

    # Check that the partitions are ext4.
    validate_script_output "mount | grep /dev/$devboot", sub { $_ =~ m/on \/boot type ext4/ };

    # There should be one partition in the LVM.
    validate_script_output "mount | grep /dev/mapper", sub { $_ =~ m/on \/ type ext4/ };

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
