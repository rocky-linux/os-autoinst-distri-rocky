package anacondatest;
use base 'fedorabase';

# base class for all Anaconda (installation) tests

# should be used in tests where Anaconda is running - when it makes sense
# to upload Anaconda logs when something fails

use testapi;

sub post_fail_hook {
    my $self = shift;

    # if error dialog is shown, click "report" - it then creates directory structure for ABRT
    my $has_traceback = 0;
    if (check_screen "anaconda_error", 10) {
        assert_and_click "anaconda_report_btn"; # Generage Anaconda ABRT logs
        $has_traceback = 1;
    }

    $self->root_console(check=>0);
    if (check_screen "root_console", 10) {
        upload_logs "/tmp/X.log";
        upload_logs "/tmp/anaconda.log";
        upload_logs "/tmp/packaging.log";
        upload_logs "/tmp/storage.log";
        upload_logs "/tmp/syslog";
        upload_logs "/tmp/program.log";
        upload_logs "/tmp/dnf.log";

        # Upload all ABRT logs
        if ($has_traceback) {
            type_string "cd /var/tmp && tar czvf var_tmp.tar.gz *";
            send_key "ret";
            upload_logs "/var/tmp/var_tmp.tar.gz";
        }

        # Upload Anaconda traceback logs
        type_string "tar czvf /tmp/anaconda_tb.tar.gz /tmp/anaconda-tb-*";
        send_key "ret";
        upload_logs "/tmp/anaconda_tb.tar.gz";
    }
    else {
        save_screenshot;
    }
}

sub root_console {
    my $self = shift;
    my %args = (
        check => 1, # whether to fail when console wasn't reached
        @_);

    if (get_var("LIVE")) {
        send_key "ctrl-alt-f2";
    }
    else {
        # Working around RHBZ 1222413, no console on tty2
        send_key "ctrl-alt-f1";
        send_key "ctrl-b";
        send_key "2";
    }
    $self->console_login(user=>"root",check=>$args{check});
}

sub select_disks {
    my ($self, $disks) = @_;
    $disks ||= 1;
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #
    # Damn animation delay can cause bad clicks here too - wait for it
    sleep 1;
    assert_and_click "anaconda_main_hub_install_destination";

    if (get_var('NUMDISKS') > 1) {
        # Multi-disk case. Select however many disks the test needs. If
        # $disks is 0, this will do nothing, and 0 disks will be selected.
        for my $n (1 .. $disks) {
            assert_and_click "anaconda_install_destination_select_disk_$n";
        }
    }
    else {
        # Single disk case.
        if ($disks == 0) {
            # Clicking will *de*-select.
            assert_and_click "anaconda_install_destination_select_disk_1";
        }
        elsif ($disks > 1) {
            die "Only one disk is connected! Cannot select $disks disks.";
        }
        # For exactly 1 disk, we don't need to do anything.
    }

    if (get_var('DISK_CUSTOM')) {
        assert_and_click "anaconda_manual_partitioning";
    }
}

sub custom_scheme_select {
    my ($self, $scheme) = @_;
    assert_and_click "anaconda_part_scheme";
    assert_and_click "anaconda_part_scheme_$scheme";
}

sub custom_change_type {
    my ($self, $type) = @_;
    # We assume we start off with / selected.
    assert_and_click "anaconda_part_device_type";
    assert_and_click "anaconda_part_device_type_$type";
    assert_and_click "anaconda_part_update_settings";
}

1;

# vim: set sw=4 et:
