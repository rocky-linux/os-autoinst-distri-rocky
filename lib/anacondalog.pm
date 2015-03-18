package anacondalog;
use base 'basetest';

use testapi;

sub post_fail_hook {
    my $self = shift;
    send_key "ctrl-alt-f2";
    my $logged_in = 0;
    if (get_var("LIVE") && check_screen "text_console_login", 20) {
        # On live installs, we need to log in
        type_string "root";
        send_key "ret";
        if (check_screen "root_logged_in", 10) {
            $logged_in = 1;
        }
    }
    elsif (check_screen "anaconda_console", 10) {
        $logged_in = 1;
    }

    if ($logged_in == 1) {
        upload_logs "/tmp/X.log";
        upload_logs "/tmp/anaconda.log";
        upload_logs "/tmp/packaging.log";
        upload_logs "/tmp/storage.log";
        upload_logs "/tmp/syslog";
        upload_logs "/tmp/program.log";
        upload_logs "/tmp/dnf.log";

        # Upload all ABRT logs
        type_string "cd /var/tmp/abrt && tar czvf abrt.tar.gz *";
        send_key "ret";
        upload_logs "/var/tmp/abrt/abrt.tar.gz";

        # Upload Anaconda logs
        type_string "tar czvf /tmp/anaconda_tb.tar.gz /tmp/anaconda-tb-*";
        send_key "ret";
        upload_logs "/tmp/anaconda_tb.tar.gz";
    }
    else {
        save_screenshot;
    }
}

1;

# vim: set sw=4 et:

