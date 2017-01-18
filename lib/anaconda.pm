package anaconda;

use strict;

use base 'Exporter';
use Exporter;

use testapi;
use utils;

our @EXPORT = qw/select_disks custom_scheme_select custom_change_type custom_change_fs custom_change_device custom_delete_part get_full_repo get_mirrorlist_url/;

sub select_disks {
    # Handles disk selection. Has one optional argument - number of
    # disks to select. Should be run when main Anaconda hub is
    # displayed. Enters disk selection spoke and then ensures that
    # required number of disks are selected. Additionally, if
    # PARTITIONING variable starts with custom_, selects "custom
    # partitioning" checkbox. Example usage:
    # after calling `select_disks(2);` from Anaconda main hub,
    # installation destination spoke will be displayed and two
    # attached disks will be selected for installation.
    my %args = (
        disks => 1,
        iscsi => {},
        @_
    );
    my %iscsi = %{$args{iscsi}};
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #
    # Damn animation delay can cause bad clicks here too - wait for it
    sleep 1;
    assert_and_click "anaconda_main_hub_install_destination";

    if (get_var('NUMDISKS') > 1) {
        # Multi-disk case. Select however many disks the test needs. If
        # $disks is 0, this will do nothing, and 0 disks will be selected.
        for my $n (1 .. $args{disks}) {
            assert_and_click "anaconda_install_destination_select_disk_$n";
        }
    }
    else {
        # Single disk case.
        if ($args{disks} == 0) {
            # Clicking will *de*-select.
            assert_and_click "anaconda_install_destination_select_disk_1";
        }
        elsif ($args{disks} > 1) {
            die "Only one disk is connected! Cannot select $args{disks} disks.";
        }
        # For exactly 1 disk, we don't need to do anything.
    }

    # Handle network disks.
    if (%iscsi) {
        assert_and_click "anaconda_install_destination_add_network_disk";
        foreach my $target (keys %iscsi) {
            my $ip = $iscsi{$target}->[0];
            my $user = $iscsi{$target}->[1];
            my $password = $iscsi{$target}->[2];
            assert_and_click "anaconda_install_destination_add_iscsi_target";
            wait_still_screen 2;
            type_safely $ip;
            wait_screen_change { send_key "tab"; };
            type_safely $target;
            # start discovery - three tabs, enter
            type_safely "\t\t\t\n";
            if ($user && $password) {
                assert_and_click "anaconda_install_destination_target_auth_type";
                assert_and_click "anaconda_install_destination_target_auth_type_chap";
                send_key "tab";
                type_safely $user;
                send_key "tab";
                type_safely $password;
            }
            assert_and_click "anaconda_install_destination_target_login";
            assert_and_click "anaconda_install_destination_select_target";
        }
        assert_and_click "anaconda_spoke_done";
    }

    # If this is a custom partitioning test, select custom partitioning.
    if (get_var('PARTITIONING') =~ /^custom_/) {
        assert_and_click "anaconda_manual_partitioning";
    }
}

sub custom_scheme_select {
    # Used for setting custom partitioning scheme (such as LVM).
    # Should be called when custom partitioning spoke is displayed.
    # Pass the name of the partitioning scheme. Needle
    # `anaconda_part_scheme_$scheme` should exist. Example usage:
    # `custom_scheme_select("btrfs");` uses needle
    # `anaconda_part_scheme_btrfs` to set partition scheme to Btrfs.
    my ($scheme) = @_;
    assert_and_click "anaconda_part_scheme";
    # Move the mouse away from the menu
    mouse_set(10, 10);
    assert_and_click "anaconda_part_scheme_$scheme";
}

sub custom_change_type {
    # Used to set different device types for specified partition (e.g.
    # RAID). Should be called when custom partitioning spoke is
    # displayed. Pass it type of partition and name of partition.
    # Needles `anaconda_part_select_$part` and
    # `anaconda_part_device_type_$type` should exist. Example usage:
    # `custom_change_type("raid", "root");` uses
    # `anaconda_part_select_root` and `anaconda_part_device_type_raid`
    # needles to set RAID for root partition.
    my ($type, $part) = @_;
    $part ||= "root";
    assert_and_click "anaconda_part_select_$part";
    assert_and_click "anaconda_part_device_type";
    # Move the mouse away from the menu
    mouse_set(10, 10);
    assert_and_click "anaconda_part_device_type_$type";
    assert_and_click "anaconda_part_update_settings";
}

sub custom_change_fs {
    # Used to set different file systems for specified partition.
    # Should be called when custom partitioning spoke is displayed.
    # Pass filesystem name and name of partition. Needles
    # `anaconda_part_select_$part` and `anaconda_part_fs_$fs` should
    # exist. Example usage:
    # `custom_change_fs("ext3", "root");` uses
    # `anaconda_part_select_root` and `anaconda_part_fs_ext3` needles
    # to set ext3 file system for root partition.
    my ($fs, $part) = @_;
    $part ||= "root";
    assert_and_click "anaconda_part_select_$part";
    # if fs is already set correctly, do nothing
    return if (check_screen "anaconda_part_fs_${fs}_selected", 5);
    assert_and_click "anaconda_part_fs";
    # Move the mouse away from the menu
    mouse_set(10, 10);
    assert_and_click "anaconda_part_fs_$fs";
    assert_and_click "anaconda_part_update_settings";
}

sub custom_change_device {
    my ($part, $devices) = @_;
    assert_and_click "anaconda_part_select_$part";
    assert_and_click "anaconda_part_device_modify";
    foreach my $device (split(/ /, $devices)) {
        assert_and_click "anaconda_part_device_${device}";
    }
    assert_and_click "anaconda_part_device_select";
    assert_and_click "anaconda_part_update_settings";
}

sub custom_delete_part {
    # Used for deletion of previously added partitions in custom
    # partitioning spoke. Should be called when custom partitioning
    # spoke is displayed. Pass the partition name. Needle
    # `anaconda_part_select_$part` should exist. Example usage:
    # `custom_delete_part('swap');` uses needle
    # `anaconda_part_select_swap` to delete previously added swap
    # partition.
    my ($part) = @_;
    return if not $part;
    assert_and_click "anaconda_part_select_$part";
    assert_and_click "anaconda_part_delete";
}

sub get_full_repo {
    my ($repourl) = @_;
    # trivial thing we kept repeating: fill out an HTTP or HTTPS
    # repo URL with flavor and arch, leave NFS ones alone (as for
    # NFS tests we just use a mounted ISO and the URL is complete)
    if ($repourl !~ m/^nfs/) {
        $repourl .= "/Everything/".get_var("ARCH")."/os";
    }
    return $repourl;
}

sub get_mirrorlist_url {
    return "mirrors.fedoraproject.org/mirrorlist?repo=fedora-" . lc(get_var("VERSION")) . "&arch=" . get_var('ARCH');
}
