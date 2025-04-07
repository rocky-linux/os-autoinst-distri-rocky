package disks;

use strict;

use base 'Exporter';
use Exporter;
use lockapi;
use testapi;
use utils;

our @EXPORT = qw(add_partitions delete_partition create_partition format_partition edit_partition edit_filesystem authenticate mount_partition resize_partition wipe_disk);

# This routine handles the authentication dialogue when it
# pops out. It provides the admin user (not root) password
# so that system change could be performed on regular
# Workstation.
sub authenticate {
    if (check_screen("auth_required", 2)) {
        my $password = get_var("USER_PASSWORD") // "weakpassword";
        type_very_safely($password);
        send_key("ret");
    }
}

# This routine adds two partitions. This layout is used in
# several testing scripts.
sub add_partitions {
    # The correct disk should be already selected,
    # but click on it anyway to make sure it is.
    assert_and_click("disks_loopdisk_listed");
    # Create the first partition.
    create_partition("primavolta", "256");
    # Select the empty space
    assert_and_click("disks_free_space");
    # Create the second partition.
    create_partition("secondavolta", "full");
    # Create the second partition.
}


# This routine deletes a partition that is defined by its number.
# In GUI it is defined as "Partition $number" which is used
# to assert. If the partition is not found, it will fail.
# The number should be passed as "one", "two" to get use
# of the precreated needles.
sub delete_partition {
    my $number = shift;
    # Select the partition.
    assert_and_click("disks_select_partition_$number");
    # Confirm that it has been selected by checking the
    # identifier.
    assert_screen("disks_partition_identifier_$number");
    # Click on the Minus symbol to delete the partition
    assert_and_click("disks_partition_delete");
    # Confirm the deletion using the Delete button.
    assert_and_click("gnome_button_delete");
    # Authenticate (if asked)
    authenticate();
    # Check that the partition has been deleted.
    # That means that the identifier disappears and the program
    # falls back to another partition and shows its identifier,
    # or it shows no identifier, if there are no partitions
    # whatsoever.
    if (check_screen("disks_partition_identifier_$number", timeout => 10)) {
        die("The partition seems not to have been deleted.");
    }
}

# This routine creates a partition in the empty space.
# You can define a name and a size. If the size is "full",
# the partition will take up the rest of the free space.
sub create_partition {
    my ($name, $size) = @_;
    # Click on the Plus button to add partition.
    assert_and_click("gnome_add_button_plus");
    # Hit Tab to arrive in the size field
    send_key("tab");
    # Type in the size
    if ($size ne "full") {
        type_very_safely("$size");
    }
    # Click on Next
    assert_and_click("next_button");
    # Hit Tab to arrive in Name field
    send_key("tab");
    # Type in the name
    type_very_safely("$name");
    # Click on Create button
    assert_and_click("gnome_button_create");
    # Authenticate if needed.
    authenticate();
    # Check that the partition has been created.
    assert_screen("disks_partition_created_$name");
}

# This routine formats the existing partition. You can
# define the number of the partition and the filesystem
# type.
sub format_partition {
    my ($number, $type, $name) = @_;
    # Select the partition
    assert_and_click("disks_select_partition_$number");
    # Open the partition menu
    assert_and_click("disks_partition_menu");
    # Select to format partition
    assert_and_click("disks_menu_format");
    # Name the filesystem
    type_very_safely($name);
    # Select the filesystem if it is visible.
    if (check_screen("disks_select_$type")) {
        diag("INFO: The required filesystem type was located on the first screen.");
        click_lastmatch();
    }
    else {
        diag("INFO: The required filesystem type was not seen on the first screen");
        assert_and_click("disks_select_other");
        assert_and_click("next_button");
        assert_and_click("disks_select_$type");
    }
    # Click on the Next button
    assert_and_click("next_button");
    # Check that there is a warning
    assert_screen("disks_warning_shown");
    # Click on the Format button to continue
    assert_and_click("gnome_button_format");
    # Authenticate if needed
    authenticate();
    # Check that the partition has been formatted.
    assert_screen("disks_partition_formatted_$number");
}

# This routine edits the type of partition and its name.
# You can select the type, the name, or both. When changed,
# the changes will be reflected on the partition overview.
sub edit_partition {
    my ($number, $type, $name) = @_;
    # Select the partition
    assert_and_click("disks_select_partition_$number");
    # Open the partition menu
    assert_and_click("disks_partition_menu");
    # Click on Edit partition
    assert_and_click("disks_menu_edit_partition");
    # Click on Selector
    assert_and_click("disks_type_selector");
    # Select the new partition type
    # The partition type might be visible right ahead,
    # if not, press the "Down" key until it has been found.
    if (check_screen("disks_select_$type")) {
        click_lastmatch();
    }
    else {
        send_key_until_needlematch("disks_select_$type", "down", 50, 1);
        click_lastmatch();
    }
    if ($name) {
        # Hit Tab to arrive on the name line
        send_key("tab");
        # Type the name of the partition
        type_very_safely($name);
    }
    # Click on the Change button
    assert_and_click("gnome_button_change");
    # Authenticate if needed
    authenticate();
    # Check that the partition has been changed
    assert_screen("disks_parttype_changed_$type");
}

# This routine edits the name of the filesystem. You need
# to set the number of the partition and the name that you
# want to set to the filesystem.
sub edit_filesystem {
    my ($number, $name) = @_;
    # Select the partition.
    assert_and_click("disks_select_partition_$number");
    # Open the partition menu
    assert_and_click("disks_partition_menu");
    # Click on Edit filesystem
    assert_and_click("disks_menu_edit_filesystem");
    # Type the name
    type_very_safely($name);
    # Click on Change
    assert_and_click("gnome_button_change");
    # Authenticate
    authenticate();
    # Check that the type has changed.
    assert_screen("disks_fstype_changed_$name");
}

# This mounts a partition with a filesystem. The partition
# can be chosen by using the $number.
sub mount_partition {
    my $number = shift;
    # Select the first partition if not selected.
    assert_and_click("disks_select_partition_$number");
    # Click on the Play symbout to mount the partition.
    assert_and_click("disks_button_mount");
    # Authenticate if necessary.
    authenticate();
    # Check that it has been mounted
    assert_screen("disks_partition_mounted_$number");
}

# This routine resizes a partition. It takes the number of
# the partition to resize and the target size of the partition.
sub resize_partition {
    my ($number, $size) = @_;
    # Select the partition
    assert_and_click("disks_select_partition_$number");
    # Open the partition menu
    assert_and_click("disks_partition_menu");
    # Select Resize partition
    assert_and_click("disks_menu_resize");
    # Authenticate
    authenticate();
    # Click into the Size field and delete
    # its content.
    assert_and_click("disks_partition_size");
    send_key("ctrl-a");
    send_key("delete");
    # Type in the new size
    type_very_safely($size);
    # Click on the Resize button
    assert_and_click("gnome_button_resize");
    # select the partition
    assert_and_click("disks_select_partition_$number");
    # Check that it has been resized.
    assert_screen("disks_partition_resized");
}

# This routine wipes the entire disk and formats it using
# the GPT partitions layout.
sub wipe_disk {
    # Format the entire disk with a GPT.
    assert_and_click("disks_dotted_menu");
    assert_and_click("disks_menu_format_disk");
    assert_and_click("gnome_button_format_disk");
    assert_and_click("gnome_button_format_confirm");
    # Do authentication
    authenticate();
    # Check that the disk has been correctly formatted.
    assert_screen("disks_disk_formatted");
}
