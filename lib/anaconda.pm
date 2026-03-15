package anaconda;

use strict;

use base 'Exporter';
use Exporter;

use testapi;
use utils;
use bugzilla;

our @EXPORT = qw/select_disks custom_scheme_select custom_add_partition custom_blivet_add_partition custom_blivet_format_partition custom_blivet_resize_partition custom_change_type custom_change_fs custom_change_device custom_delete_part get_full_repo check_help_on_pane get_mirrorlist_url crash_anaconda_text report_bug_text/;

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
    assert_screen "anaconda_main_hub", 300;    #
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

    # If this is a custom partitioning test, select custom partitioning. For testing blivet-gui,
    # name of test module should start with custom_blivet_, otherwise it should start with custom_.
    if (get_var('PARTITIONING') =~ /^custom_blivet_/) {
        assert_and_click "anaconda_manual_blivet_partitioning";
    } elsif (get_var('PARTITIONING') =~ /^custom_/) {
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
    # workaround for bug aarch64 tests sometimes hit - menu doesn't
    # open when clicked. just click it again.
    if (check_screen "anaconda_part_scheme_active", 5) {
        assert_and_click "anaconda_part_scheme_active";
        mouse_set(10, 10);
    }
    assert_and_click "anaconda_part_scheme_$scheme";
}

sub custom_blivet_add_partition {
    # Used to add partition on blivet-gui partitioning screen
    # in Anaconda. Should be called when blivet-gui is displayed and free space is selected.
    # You can pass device type for partition (needle tagged anaconda_blivet_devicetype_$devicetype should exist),
    # whether partitions should be of RAID1 (devicetype is then automatically handled) - you then
    # need to have two disks added, size of that partition in MiBs, desired filesystem of that partition
    # (anaconda_blivet_part_fs_$filesystem should exist) and mountpoint of that partition (e. g. string "/boot").
    my %args = (
        devicetype => "",
        raid1 => 0,
        size => 0,
        filesystem => "",
        mountpoint => "",
        @_
    );
    $args{devicetype} = "raid" if $args{raid1};

    assert_and_click "anaconda_blivet_part_add";
    mouse_set(10, 10);
    if ($args{devicetype}) {
        assert_and_click "anaconda_blivet_part_devicetype";
        mouse_set(10, 10);
        assert_and_click "anaconda_blivet_part_devicetype_$args{devicetype}";
    }

    if ($args{raid1}) {
        # for RAID1, two disks should be selected
        send_key "tab";
        send_key "down";
        send_key "spc";
        assert_screen "anaconda_blivet_vdb_selected";

        assert_and_click "anaconda_blivet_raidlevel_select";
        mouse_set(10, 10);
        assert_and_click "anaconda_blivet_raidlevel_raid1";
    }

    if ($args{size}) {
        assert_and_click "anaconda_blivet_size_unit";
        assert_and_click "anaconda_blivet_size_unit_mib";

        send_key "shift-tab";    # input is one tab back from unit selection listbox

        # size input can contain whole set of different values, so we can't match it with needle
        type_safely $args{size} . "\n";
    }
    # if no filesystem was specified or filesystem is already selected, do nothing
    if ($args{filesystem} && !check_screen("anaconda_blivet_part_fs_$args{filesystem}_selected", 5)) {
        assert_and_click "anaconda_blivet_part_fs";
        # Move the mouse away from the menu
        mouse_set(10, 10);
        assert_and_click "anaconda_blivet_part_fs_$args{filesystem}";
    }
    if ($args{mountpoint}) {
        assert_and_click "anaconda_blivet_mountpoint";
        type_safely $args{mountpoint} . "\n";
    }
    # seems we can get a lost click here if we click too soon
    wait_still_screen 3;
    assert_and_click "anaconda_blivet_btn_ok";
    # select "free space" in blivet-gui if it exists, so we could run this function again to add another partition
    if (check_screen("anaconda_blivet_free_space", 15)) {
        assert_and_click "anaconda_blivet_free_space";
    }
}

sub custom_add_partition {
    # Used to add partition on Rocky custom-gui partitioning screen
    # in Anaconda. Should be called when custom-gui is displayed and free space is selected.
# You can pass device type for partition (needle tagged anaconda_custom_devicetype_$devicetype should exist), size of that partition in MiBs, desired filesystem of that partition
    # (anaconda_custom_part_fs_$filesystem should exist) and mountpoint of that partition (e. g. string "/boot").
    my %args = (
        devicetype => "",
        raidlevel => 0,
        size => 0,
        filesystem => "",
        mountpoint => "",
        @_
    );
    $args{devicetype} = "raid" if $args{raidlevel};

    # send tab until 'add' button is selected, then press
    # the number of tabs needed seems to depend on whether a partition has already been added
    send_key_until_needlematch("anaconda_custom_part_add", "tab");
    send_key "spc";

    # supply the mountpoint
    assert_screen "anaconda_custom_mountpoint";
    type_safely $args{mountpoint};
    send_key "tab";
    send_key "tab";
    send_key "tab";
    assert_screen "anaconda_custom_size";
    # supply the desired size
    # if size is not provided, leave empty to use the remaining disk space
    if ($args{size}) {
        type_safely $args{size};
    }
    send_key "tab";
    send_key "tab";
    assert_screen "anaconda_custom_btn_add_mountpoint";
    send_key "spc";

    # if no devicetype was specified or devicetype is already selected, do nothing
    if (($args{devicetype} && !check_screen("anaconda_custom_part_fs_$args{devicetype}_selected", 5))) {
        # send 'tab' until the Device Type dropdown is selected
        send_key_until_needlematch("anaconda_custom_part_devicetype_selected", "tab");
        send_key "spc";
        # send 'down' until the correct devicetype is selected
        send_key_until_needlematch("anaconda_custom_part_devicetype_$args{devicetype}", "down");
        send_key "spc";
    }
    # if no filesystem was specified or filesystem is already selected, do nothing
    if ($args{filesystem} && !check_screen("anaconda_custom_part_fs_$args{filesystem}_selected", 5)) {
        # send 'tab' until the File System dropdown is selected
        send_key_until_needlematch("anaconda_custom_part_fs_selected", "tab");
        send_key "spc";
        # send 'down' until the correct filesystem is selected
        send_key_until_needlematch("anaconda_custom_part_fs_$args{filesystem}_selected", "down");
        send_key "spc";
    }
    if ($args{raidlevel}) {
        # send 'tab' until Raid Level dropdown is selected
        send_key_until_needlematch("anaconda_custom_part_raidlevel_selected", "tab");
        send_key "spc";
        #choose RAID level from dropdown
        send_key_until_needlematch("anaconda_custom_part_raid_1_selected", "down");
        send_key "spc";
    }

    # select "free space" in custom-gui if it exists, so we could run this function again to add another partition
    if (check_screen("anaconda_custom_free_space", 15)) {
        assert_and_click "anaconda_custom_free_space";
    }
}

sub custom_blivet_format_partition {
    # This subroutine formats a selected partition. To use it, you must select the
    # partition by other means before you format it using this routine.
    # You have to create a needle for any non-existing filesystem that is
    # passed via the $type, such as anaconda_blivet_part_fs_ext4.
    my %args = @_;
    # Start editing the partition and select the Format option
    assert_and_click "anaconda_blivet_part_edit";
    assert_and_click "anaconda_blivet_part_format";
    # Select the appropriate filesystem type.
    assert_and_click "anaconda_blivet_part_drop_select";
    assert_and_click "anaconda_blivet_part_fs_$args{type}";
    wait_still_screen 2;
    # Fill in the label if needed.
    send_key "tab";
    if ($args{label}) {
        type_very_safely $args{label};
    }
    # Fill in the mountpoint.
    send_key "tab";
    type_very_safely $args{mountpoint};
    assert_and_click "anaconda_blivet_part_format_button";
}

sub custom_blivet_resize_partition {
    # This subroutine resizes the selected (active) partition to a given value. Note, that
    # if the selected value is bigger than the available space, it will only be
    # resized to fill up the available space no matter the number.
    # This routine cannot will not be able to select a particular partition!!!
    my %args = @_;
    # Start editing the partition and select the Resize option
    assert_and_click "anaconda_blivet_part_edit";
    assert_and_click "anaconda_blivet_part_resize";
    # Select the appropriate units. Note, that there must a be needle existing
    # for each possible unit that you might want to use, such as
    # "anaconda_blivet_size_unit_gib".
    assert_and_click "anaconda_blivet_part_drop_select";
    assert_and_click "anaconda_blivet_size_unit_$args{units}";
    # Move back to the value field.
    send_key "shift-tab";
    # Type in the new size.
    type_very_safely $args{size};
    assert_and_click "anaconda_blivet_part_resize_button";
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
    wait_still_screen 5;
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
    wait_still_screen 5;
    # if fs is already set correctly, do nothing
    return if (check_screen "anaconda_part_fs_${fs}_selected", 5);
    assert_and_click "anaconda_part_fs";
    # Move the mouse away from the menu
    mouse_set(10, 10);
    assert_and_click "anaconda_part_fs_$fs";
    assert_and_click "anaconda_part_update_settings";
    wait_still_screen 5;
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
    wait_still_screen 5;
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
    # repo URL with flavor and arch, leave hd & NFS ones alone
    # (as for those tests we just use a mounted ISO and URL is complete)
    if ($repourl !~ m/^(nfs|hd:)/) {
        # Rocky Linux default repo is BaseOS. This subdirectory
        # should be added to ${LOCATION}.
        $repourl .= "/BaseOS/" . get_var("ARCH") . "/os";
    }
    return $repourl;
}

sub get_mirrorlist_url {
    return "mirrors.rockylinux.org/mirrorlist?repo=rocky-BaseOS-" . lc(get_var("VERSION")) . "&arch=" . get_var('ARCH');
}

sub check_help_on_pane {
    # This subroutine opens the selected Anaconda pane and checks
    # if the Help button can be clicked to obtain relevant help.
    #
    # Pass an argument to select particular pane to check.
    my $screen = shift;

    # Some Help buttons need to be accessed directly according
    # to various installation steps (and not from the main hub),
    # namely the Main hub Help button, Language selection Help button
    # and Installation progress Help button. For the aforementioned
    # step, we are skipping selecting the panes.
    if ($screen ne "main" && $screen ne "language_selection" && $screen ne "installation_progress") {
        send_key_until_needlematch("anaconda_main_hub_$screen", "shift-tab");
        wait_screen_change { click_lastmatch; };
    }
    # For Help, click on the the Help button.
    assert_and_click "anaconda_help_button";

    # On the main hub, the Help summary is shown, from where a link
    # takes us to Installation progress. This is a specific situation,
    # so let's handle this differently.
    if ($screen eq "main") {
        # Check the Installation Summary screen.
        assert_screen "anaconda_help_summary";
        # Click on Installation Progress link
        assert_and_click "anaconda_help_progress_link";
        # Check the Installation Progress screen
        assert_screen "anaconda_help_progress";
    }
    # Otherwise, only check the relevant screen.
    else {
        # Rocky help has a level of indirection here. Need to click a link first...
        if ((get_var('DISTRI') eq "rocky"))
        {
            if ($screen eq "keyboard_layout" || $screen eq "language_support" || $screen eq "time_date")
            {
                assert_and_click "anaconda_help_localization_link";
                # Specifically for language_support and time_date press page-down
                if ($screen eq "language_support" || $screen eq "time_date")
                {
                    send_key "spc";
                }
            }
        }
        assert_screen "anaconda_help_$screen";
    }
    # Close Help window
    assert_and_click "anaconda_help_quit";
    # Where panes were not opened, we will not close them.
    if ($screen ne "main" && $screen ne "language_selection" && $screen ne "installation_progress") {
        assert_and_click "anaconda_spoke_done";
    }
    # In the situation, when we do not arrive at main hub, we will skip
    # testing that main hub is shown.
    if ($screen ne "language_selection" && $screen ne "installation_progress") {
        # on leaving a spoke, it is highlighted on the main hub, which
        # can throw off the match here. so we'll try hitting shift-tab
        # a few times to shift focus
        send_key_until_needlematch("anaconda_main_hub", "shift-tab");
        # things can take some time to settle after this one
        wait_still_screen 10 if ($screen eq "install_destination");
    }
}

sub crash_anaconda_text {
    # This routine uses the Anaconda crash trigger to break the ongoing Anaconda installation to simulate
    # an Anaconda crash and runs a series of steps that results in creating a bug in Bugzilla.
    # It is used in the `install_text.pm` test and can be switched on by using the CRASH_REPORT
    # variable set to 1.
    #
    # tty3 has a shell on all f31+ installer and live images
    select_console "tty3-console";
    assert_screen("anaconda_text_install_shell");
    # We use the trigger command to do the simulated crash.
    type_string "kill -USR1 `cat /var/run/anaconda.pid`\n";
    # And navigate back to the main panel of Anaconda. This should require
    select_console "tty1-console";
    assert_screen("anaconda_text_install_main");
    # We wait until the crash menu appears. This usually takes some time,
    # so let's try for 300 seconds, this should be long enough.
    my $trials = 1;
    until (check_screen("anaconda_text_crash_menu_ready") || $trials > 30) {
        sleep 10;
        ++$trials;
    }
    # If the crash menu never appears, let's assert it to fail.
    if ($trials > 30) {
        assert_screen("anaconda_text_crash_menu_ready");
    }

}

sub report_bug_text {
    # This routine handles the Bugzilla reporting after a simulated crash on
    # a textual console.
    # We will not create a needle for every menu item, and we will fail,
    # if there will be no positive Bugzilla confirmation shown at the end
    # of the process and then we will fail.
    #
    # Let us record the time of this test run. Later, we will use it to
    # limit the Bugzilla search.
    my $timestamp = time();
    #
    # First, collect the credentials.
    my $login = get_var("BUGZILLA_LOGIN");
    my $password = get_var("_SECRET_BUGZILLA_PASSWORD");
    my $apikey = get_var("_SECRET_BUGZILLA_APIKEY");
    # Choose item 1 - Report the bug.
    type_string "1\n";
    sleep 2;
    # Choose item 1 - Report to Bugzilla
    type_string "1\n";
    sleep 5;
    # Do login.
    type_string $login;
    type_string "\n";
    sleep 5;
    # Enter the name of the Zilla.
    type_password $password;
    type_string "\n";
    sleep 10;
    # Save the report without changing it.
    # It would need some more tweaking to actually type into the report, but since
    # it is reported even if unchanged, we leave it as such.
    type_string ":wq\n";
    # Wait until the Crash menu appears again.
    # The same screen shows the result of the Bugzilla operation,
    # so if the needle matches, the bug has been created in Bugzilla.
    # Bugzilla connection is slow so we need to wait out some time,
    # therefore let's use a cycle that will check each 10 seconds and
    # ends if there is no correct answer from Bugzilla in 120 seconds.
    my $counter = 0;
    until (check_screen("anaconda_text_bug_reported") || $counter > 12) {
        sleep 10;
        ++$counter;
    }
    # Sometimes, Bugzilla throws out a communication error although the bug has been
    # created successfully. If this happens, we will softfail and leave the creation
    # check to a later step.
    if ($counter > 12) {
        record_soft_failure "Warning: Bugzilla has reported an error which could mean that the bug has not been created correctly, but it probably is not a real problem, if the test has not failed completely. ";
    }

    # Now, let us check with Bugzilla directly, if the bug has been created.
    # First, we shall get a Bugzilla format timestamp to use it in the query.
    # The timestamp will limit the list of bugs to those that have been created since
    # the then -> resulting with high probability in the one that this test run
    # has just created.
    $timestamp = convert_to_bz_timestamp($timestamp);
    # Then we fetch the latest bug from Bugzilla.
    my $lastbug = get_newest_bug($timestamp, $login);
    unless ($lastbug) {
        die "Bugzilla returned no newly created bug. It seems that the bug has not been created.";
    }
    else {
        print("BUGZILLA: The last bug was found: $lastbug\n");
    }
    # We have found that the bug indeed is in the bugzilla (otherwise
    # we would have died already) so now we close it to clean up after this test run.
    my $result = close_notabug($lastbug, $apikey);
    unless ($result) {
        record_soft_failure "The bug has not been closed for some reason. Check manually.";
    }
    else {
        print("BUGZILLA: The last bug $lastbug changed status to CLOSED.\n");
    }

    # Quit anaconda
    type_string "4\n";

}
