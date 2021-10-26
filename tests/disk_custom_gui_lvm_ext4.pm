use base "anacondatest";
use strict;
use testapi;
use anaconda;

sub run {
    my $self = shift;
    # Go to INSTALLATION DESTINATION and ensure the disk is selected.
    # Because PARTITIONING starts with 'custom_', this will select custom.
    select_disks();
    assert_and_click "anaconda_spoke_done";

    if (get_var("UEFI")) {
        # if we're running on UEFI, we need esp
        custom_add_partition(size => 512, mountpoint => '/boot/efi', filesystem => 'efi_filesystem');
    }
    if (get_var("OFW")) {
        custom_add_partition(size => 4, filesystem => 'ppc_prep_boot');
    }

    custom_add_partition(size => 512, mountpoint => '/boot', filesystem => 'ext4');
    custom_add_partition(size => 512, mountpoint => 'swap', filesystem => 'swap');

    # LVM vg already exists, so just add a volume
    # add lvm LV with ext4 and mount it as /
    custom_add_partition(devicetype => 'lvmlv', filesystem => 'ext4', mountpoint => '/');

    # Confirm changes
    assert_and_click "anaconda_spoke_done";
    assert_and_click "anaconda_part_accept_changes";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
