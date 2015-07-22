package anacondalog;
use base 'fedorabase';

use testapi;

sub post_fail_hook {
    my $self = shift;

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

        # Upload Anaconda logs
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
        check => 1,
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

1;

# vim: set sw=4 et:

