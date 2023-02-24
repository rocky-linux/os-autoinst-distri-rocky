use base "anacondatest";
use strict;
use testapi;
use anaconda;

sub run {
    my $self = shift;
    # Go to INSTALLATION DESTINATION and ensure the disk is selected.
    # Because PARTITIONING starts with 'custom_blivet', this will select blivet-gui.
    select_disks();
    assert_and_click "anaconda_spoke_done";

    if (get_var("UEFI")) {
        # if we're running on UEFI, we need esp
        custom_blivet_add_partition(size => 512, mountpoint => '/boot/efi', filesystem => 'efi_filesystem');
    }
    if (get_var("OFW")) {
        custom_blivet_add_partition(size => 4, filesystem => 'ppc_prep_boot');
    }

    custom_blivet_add_partition(size => 512, mountpoint => '/boot', filesystem => 'ext4');
    # add new LVM VG
    custom_blivet_add_partition(devicetype => 'lvmvg');
    # select newly created LVM device for adding new LV
    assert_and_click "anaconda_blivet_volumes_icon";
    # add lvm LV with ext4 and mount it as /
    custom_blivet_add_partition(devicetype => 'lvmlv', filesystem => 'ext4', mountpoint => '/');

    assert_and_click "anaconda_spoke_done";
    assert_and_click "anaconda_part_accept_changes";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300;    #

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
