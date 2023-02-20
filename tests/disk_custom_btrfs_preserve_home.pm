use base "anacondatest";
use strict;
use testapi;
use utils;
use anaconda;


sub use_current_partition {
    my ($partition, $reformat) = @_;

    # Select the partition
    my $match = $partition;
    # needle names can't have / in them
    $match =~ s,/,,;
    assert_and_click "anaconda_part_select_$match";
    # Select the mountpoint field
    send_key_until_needlematch("anaconda_part_mountpoint_selected", "tab", 20);
    # Type in the mountpoint
    if ($partition eq "root") {
        type_very_safely "/";
    }
    else {
        type_very_safely "/$partition";
    }
    # Click on reformat if we so wish
    if ($reformat == 1) {
        assert_and_click "anaconda_part_device_reformat";
    }
    # Update chosen settings
    assert_and_click "anaconda_part_update_settings";
    # Wait for the UI to settle down.
    wait_still_screen 5;
}

sub run {
    my $self = shift;
    # Go to INSTALLATION DESTINATION and ensure the disk is selected.
    # Because PARTITIONING starts with 'custom_', this will select custom.
    select_disks();
    assert_and_click "anaconda_spoke_done";

    # Manual partitioning spoke should be displayed. Select BTRFS
    # partitioning scheme
    custom_scheme_select("btrfs");
    # Select the currently installed system
    assert_and_click "anaconda_part_use_current";

    # Use the home partition from the current scheme
    use_current_partition("home", 0);
    # Use the boot partition from the current scheme
    use_current_partition("boot", 1);
    # Use /boot/efi from current scheme, if we're EFI
    use_current_partition("boot/efi", 1) if (get_var "UEFI");

    # Select the root partition from the current scheme
    # and delete it
    assert_and_click "anaconda_part_select_root";
    assert_and_click "anaconda_part_delete";
    assert_and_click "anaconda_part_confirm_delete";

    # Add the new root partition to the scheme
    assert_and_click "anaconda_part_add";
    type_very_safely "/\n";

    # Confirm changes
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
