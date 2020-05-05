use base "anacondatest";
use strict;
use testapi;
use anaconda;
use utils;

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

    # Partitioning starts out of the LVM on VD1. We will use it to recreate
    # the "/boot" partition in there.
    custom_blivet_format_partition(type => 'ext4', label => 'boot', mountpoint => '/boot');

    # Select the LVM root partition, resize it, and format it.
    assert_and_click "anaconda_blivet_volumes_icon";
    if (check_screen "anaconda_blivet_part_root_inactive") {
        # If the root partition is not active, click on it to 
        # activate it.
        assert_and_click "anaconda_blivet_part_root_inactive";
    }
    custom_blivet_resize_partition(size => '13', units => 'GiB');

    # Now format the resized root partition
    custom_blivet_format_partition(type => 'ext4', label => 'root', mountpoint => '/');

    # Select the newly created free space
    assert_and_click "anaconda_blivet_free_space";

    # Create a partition and format it.
    custom_blivet_add_partition(filesystem => 'ext4', mountpoint => '/home');

    # Close the spoke.
    assert_and_click "anaconda_spoke_done";

    # Confirm changes
    assert_and_click "anaconda_part_accept_changes";
}

sub test_flags {
        return { fatal => 1 };
}

1;
