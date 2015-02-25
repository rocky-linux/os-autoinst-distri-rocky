package anacondalog;
use base 'basetest';

use testapi;

sub post_fail_hook {
    my $self = shift;
    send_key "ctrl-alt-f2";
    if (check_screen "anaconda_console", 10) {
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
}

1;

# vim: set sw=4 et:

