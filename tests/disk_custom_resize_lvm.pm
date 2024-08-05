use base "anacondatest";
use strict;
use testapi;
use anaconda;
use utils;

sub goto_mountpoint {
    send_key_until_needlematch("anaconda_part_mountpoint_selected", "tab", 20);
}

sub run {
    my $self = shift;
    # Navigate to "Installation destionation" and select blivet-gui
    # to manipulate the partitions. This will be automatically
    # done using the following method, because PARTITIONING starts
    # with "custom_blivet".
    select_disks();
    assert_and_click "anaconda_spoke_done";

    # The following procedure will use Custom Partitioning to resize the root partition from
    # a previous Linux installation and prepare the disk for new installation
    # which will be then followed through.

    # Custom partitioning shows that an existing installations is there on the disk,
    # we need to select it to proceed.
    assert_and_click "anaconda_part_use_current";

    # At first, we will recreate the /boot mountpoint in the existing installation
    # and reformat it.
    #
    assert_and_click "anaconda_part_select_boot";
    # navigate to "Mountpoint"
    goto_mountpoint();
    type_very_safely "/boot";
    assert_and_click "anaconda_part_device_reformat";
    assert_and_click "anaconda_part_update_settings";
    # give it a few seconds to update
    wait_still_screen 5;

    # For UEFI based images, we need to reassign the efi boot
    # mountpoint as well
    if (get_var("UEFI") == 1) {
        assert_and_click "anaconda_part_select_efiboot";
        goto_mountpoint();
        type_very_safely "/boot/efi";
        assert_and_click "anaconda_part_device_reformat";
        assert_and_click "anaconda_part_update_settings";
        # give it a second or two to update
        wait_still_screen 5;
    }

    # Now resize and format the current root partition
    assert_and_click "anaconda_part_select_root";
    # Navigate to Mountpoint
    goto_mountpoint();
    type_very_safely "/";
    # Skip to the Size window
    send_key "tab";
    type_very_safely "11.5 GiB";
    # Reformat and update the partition
    assert_and_click "anaconda_part_device_reformat";
    assert_and_click "anaconda_part_update_settings";
    # give it a second or two to update
    wait_still_screen 2;
    # Check that the partition has been resized for 11.5GiB
    assert_screen "device_root_resized_eleven_point_five";

    # Add new /home partition into the emptied space.
    assert_and_click "anaconda_part_add";

    # The previous step brings us into a mountpoint field
    # of the pop-up window, so we only need to fill the value in.
    # Also, it seems that leaving the size field empty automatically
    # suggests to use the remaining free space.
    type_very_safely "/home";
    send_key "tab";
    assert_and_click "anaconda_part_add_mountpoint";

    # Close the spoke.
    assert_and_click "anaconda_spoke_done";

    # Confirm changes
    assert_and_click "anaconda_part_accept_changes";
}

sub test_flags {
    return {fatal => 1};
}

1;
