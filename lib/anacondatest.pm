package anacondatest;
use base 'basetest';

# base class for all Anaconda (installation) tests

# should be used in tests where Anaconda is running - when it makes sense
# to upload Anaconda logs when something fails. Many tests using this as a
# base likely will also want to `use anaconda` for commonly-used functions.

use testapi;
use utils;

sub post_fail_hook {
    my $self = shift;

    # if error dialog is shown, click "report" - it then creates directory structure for ABRT
    my $has_traceback = 0;
    if (check_screen "anaconda_error", 10) {
        assert_and_click "anaconda_error_report";
        $has_traceback = 1;
    } elsif (check_screen "anaconda_text_error", 10) {  # also for text install
        type_string "1\n";
        $has_traceback = 1;
    }

    save_screenshot;
    $self->root_console();
    upload_logs "/tmp/X.log", failok=>1;
    upload_logs "/tmp/anaconda.log", failok=>1;
    upload_logs "/tmp/packaging.log", failok=>1;
    upload_logs "/tmp/storage.log", failok=>1;
    upload_logs "/tmp/syslog", failok=>1;
    upload_logs "/tmp/program.log", failok=>1;
    upload_logs "/tmp/dnf.log", failok=>1;
    upload_logs "/tmp/dnf.librepo.log", failok=>1;
    upload_logs "/tmp/dnf.rpm.log", failok=>1;

    if ($has_traceback) {
        # Upload Anaconda traceback logs
        script_run "tar czf /tmp/anaconda_tb.tar.gz /tmp/anaconda-tb-*";
        upload_logs "/tmp/anaconda_tb.tar.gz";
    }

    # Upload all ABRT logs (if there are any)
    unless (script_run 'test -n "$(ls -A /var/tmp)" && tar czf /var/tmp/var_tmp.tar.gz /var/tmp') {
        upload_logs "/var/tmp/var_tmp.tar.gz";
    }

    # Upload /var/log
    unless (script_run "tar czf /tmp/var_log.tar.gz /var/log") {
        upload_logs "/tmp/var_log.tar.gz";
    }

    # Upload anaconda core dump, if there is one
    unless (script_run "ls /tmp/anaconda.core.* && tar czf /tmp/anaconda.core.tar.gz /tmp/anaconda.core.*") {
        upload_logs "/tmp/anaconda.core.tar.gz";
    }
}

sub root_console {
    # Switch to an appropriate TTY and log in as root.
    my $self = shift;
    my %args = (
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
    console_login(user=>"root");
}

1;

# vim: set sw=4 et:
