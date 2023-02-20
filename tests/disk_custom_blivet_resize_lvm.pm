use base "anacondatest";
use strict;
use testapi;
use anaconda;
use utils;

sub activate {
    # This subroutine activates a partition in Blivet environment.
    # Due to some failures on different architectures, probably caused by their
    # slowliness, we will need to do the partition activation proces several
    # times to make sure the proper partition gets activated.
    my $partition = shift;
    my $count = 12;
    assert_screen 'anaconda_blivet_disk_logical_view';
    while (check_screen "anaconda_blivet_part_inactive_$partition" and $count > 0) {
        assert_and_click "anaconda_blivet_part_inactive_$partition";
        sleep 5;
        $count -= 1;
    }
}

sub run {
    my $self = shift;
    # Navigate to "Installation destionation" and select blivet-gui
    # to manipulate the partitions. This will be automatically
    # done using the following method, because PARTITIONING starts
    # with "custom_blivet".
    select_disks();
    assert_and_click "anaconda_spoke_done";

    # The following procedure will use Blivet to resize the root partition from
    # a previous Linux installation and prepare the disk for new installation
    # which will be then followed through.

    # Partitioning starts out of the LVM on VD1 or VD2 (for ppc64le)
    # We will use it to recreate the "/boot" partition in there.
    # In UEFI, we will need to deal with the /boot/efi partition first.
    if (get_var("UEFI") == 1) {
        #The efi partition should be already activated. So reformat it and remount.
        custom_blivet_format_partition(type => 'efi_filesystem', label => 'efiboot', mountpoint => '/boot/efi');
        wait_still_screen 5;
    }

    # Select the boot partition and reformat it and remount.
    my $devboot = 'boot';
    if (get_var('OFW')) {
        # for PowerPC vda1 is PreP partition.
        $devboot = 'vda2';
    }
    activate($devboot);
    # Boot is the only ext4 partition on that scheme, so we will use that to make a needle.
    wait_still_screen 5;
    custom_blivet_format_partition(type => 'ext4', label => 'boot', mountpoint => '/boot');
    wait_still_screen 5;

    # Select the LVM root partition, resize it, and format it.
    assert_and_click "anaconda_blivet_volumes_icon";
    wait_still_screen 5;
    # Activate root partition if not active already
    activate("root");
    custom_blivet_resize_partition(size => '13', units => 'GiB');
    wait_still_screen 5;
    # Check that the partition has been correctly resized to 13G.
    assert_screen "device_root_resized_thirteen";

    # Now format the resized root partition. It seems that the focus returns to the first
    # partition in the view, so we need to activate this again before we attempt to do
    # anything to the partition.
    activate("root");
    custom_blivet_format_partition(type => 'ext4', label => 'root', mountpoint => '/');
    wait_still_screen 5;

    # Select the newly created free space
    assert_and_click "anaconda_blivet_free_space";

    # Create a partition and format it.
    custom_blivet_add_partition(filesystem => 'ext4', mountpoint => '/home');
    wait_still_screen 5;

    # Close the spoke.
    assert_and_click "anaconda_spoke_done";
    wait_still_screen 5;

    # Confirm changes
    assert_and_click "anaconda_part_accept_changes";
}

sub test_flags {
    return {fatal => 1};
}

1;
