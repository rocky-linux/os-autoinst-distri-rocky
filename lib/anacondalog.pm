package anacondalog;
use base 'basetest';

use testapi;

sub post_fail_hook {
    my $self = shift;
    send_key "ctrl-alt-f2";
    if (check_screen "anaconda_console", 10) {
        upload_logs "/tmp/X.log";  # TODO: it can't type "X"
        upload_logs "/tmp/anaconda.log";
        upload_logs "/tmp/packaging.log";
        upload_logs "/tmp/storage.log";
        upload_logs "/tmp/syslog";
        upload_logs "/tmp/program.log";
    }
}

1;

# vim: set sw=4 et:

