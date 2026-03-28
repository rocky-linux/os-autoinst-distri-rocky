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
    my $devboot = 'vda2';

    # In upstream the variants for $devboot are removed. We currently test in
    # Rocky 9 and 10 which span the anaconda change mentioned in this commit
    # message...
    #
    # commit f7a8550258d467bf722e9a0726723756c6769faa
    # Author: Adam Williamson <awilliam@redhat.com>
    # Date:   Tue Aug 16 10:29:03 2022 -0400
    #
    # Create biosboot partitions in blivet tests
    #
    # From anaconda-37.12.1, anaconda default to GPT for all BIOS
    # installs. So we need to create a BIOS boot partition when doing
    # a BIOS install. I think all other potential configs (x86_64
    # UEFI, aarch64 (UEFI), ppc64le (OFW)) are covered under the other
    # two paths, so just making this `else` should be OK.
    #
    # Signed-off-by: Adam Williamson <awilliam@redhat.com>
    #
    # ...thus we need to support two variants and logically toggle
    # when the major OS version changes as well as recognize BIOS or
    # UEFI boot mode.
    if ((get_var('DISTRI') eq 'rocky') && (get_version_major() < 10) && (get_var('UEFI') ne "1")) {
        $devboot = 'vda1';
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
