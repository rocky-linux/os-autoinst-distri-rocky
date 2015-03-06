use base "anacondalog";
use strict;
use testapi;

sub run {
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    assert_and_click "anaconda_main_hub_install_destination";

    # Select both disks for installation
    assert_screen "anaconda_install_destination_two_disks";
    assert_and_click "anaconda_install_destination_select_disk_1";
    assert_and_click "anaconda_install_destination_select_disk_2";

    # Select manual partitioning
    assert_and_click "anaconda_manual_partitioning";

    assert_and_click "anaconda_spoke_done";

    # Manual partitioning spoke should be displayed

    # Add /boot partition
    assert_and_click "anaconda_part_plus_button";
    assert_and_click "anaconda_part_list_box_button";
    assert_and_click "anaconda_part_list_box_boot";
    assert_and_click "anaconda_part_desired_capacity";

    type_string "200M";

    assert_and_click "anaconda_part_add_mountpoint";

    # Add swap partition
    assert_and_click "anaconda_part_plus_button";
    assert_and_click "anaconda_part_list_box_button";
    assert_and_click "anaconda_part_list_box_swap";
    assert_and_click "anaconda_part_desired_capacity";

    type_string "2G";

    assert_and_click "anaconda_part_add_mountpoint";

    # Add root partition
    assert_and_click "anaconda_part_plus_button";
    assert_and_click "anaconda_part_list_box_button";
    assert_and_click "anaconda_part_list_box_root";

    assert_and_click "anaconda_part_add_mountpoint";

    # Change type to RAID
    assert_and_click "anaconda_part_device_type";
    assert_and_click "anaconda_part_raid_list";
    assert_and_click "anaconda_part_update_settings";

    assert_and_click "anaconda_spoke_done";
    assert_and_click "anaconda_part_accept_changes";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
