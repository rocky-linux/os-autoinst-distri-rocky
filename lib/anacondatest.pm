package anacondatest;

use strict;

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
    if (check_screen "anaconda_error_report", 10) {
        assert_and_click "anaconda_error_report";
        $has_traceback = 1;
    } elsif (check_screen "anaconda_text_error", 10) {    # also for text install
        type_string "1\n";
        $has_traceback = 1;
    }

    save_screenshot;
    $self->root_console();
    # if we're in dracut, do things different
    my $dracut = 0;
    if (check_screen "root_console_dracut", 0) {
        $dracut = 1;
        script_run "dhclient";
    }
    # if we don't have tar or a network connection, we'll try and at
    # least send out *some* kinda info via the serial line
    my $hostip = testapi::host_ip();
    if (script_run "ping -c 2 ${hostip}") {
        if ($dracut) {
            script_run 'printf "\n** RDSOSREPORT **\n" > /dev/' . $serialdev;
            script_run "cat /run/initramfs/rdsosreport.txt > /dev/${serialdev}";
            return;
        }
        script_run 'printf "\n** IP ADDR **\n" > /dev/' . $serialdev;
        script_run "ip addr > /dev/${serialdev} 2>&1";
        script_run 'printf "\n** IP ROUTE **\n" > /dev/' . $serialdev;
        script_run "ip route > /dev/${serialdev} 2>&1";
        script_run 'printf "\n** NETWORKMANAGER.SERVICE STATUS **\n" > /dev/' . $serialdev;
        script_run "systemctl --no-pager -l status NetworkManager.service > /dev/${serialdev} 2>&1";
        script_run 'printf "\n** X.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/X.log > /dev/${serialdev}";
        script_run 'printf "\n** ANACONDA.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/anaconda.log > /dev/${serialdev}";
        script_run 'printf "\n** PACKAGING.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/packaging.log > /dev/${serialdev}";
        script_run 'printf "\n** STORAGE.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/storage.log > /dev/${serialdev}";
        script_run 'printf "\n** SYSLOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/syslog > /dev/${serialdev}";
        script_run 'printf "\n** PROGRAM.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/program.log > /dev/${serialdev}";
        script_run 'printf "\n** DNF.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/dnf.log > /dev/${serialdev}";
        script_run 'printf "\n** DNF.LIBREPO.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/dnf.librepo.log > /dev/${serialdev}";
        script_run 'printf "\n** DNF.RPM.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/dnf.rpm.log > /dev/${serialdev}";
        script_run 'printf "\n** DBUS.LOG **\n" > /dev/' . $serialdev;
        script_run "cat /tmp/dbus.log > /dev/${serialdev}";
        return;
    }

    if ($dracut) {
        upload_logs "/run/initramfs/rdsosreport.txt", failok => 1;
        # that's all that's really useful, so...
        return;
    }

    upload_logs "/tmp/X.log", failok => 1;
    upload_logs "/tmp/anaconda.log", failok => 1;
    upload_logs "/tmp/packaging.log", failok => 1;
    upload_logs "/tmp/storage.log", failok => 1;
    upload_logs "/tmp/syslog", failok => 1;
    upload_logs "/tmp/program.log", failok => 1;
    upload_logs "/tmp/dnf.log", failok => 1;
    upload_logs "/tmp/dnf.librepo.log", failok => 1;
    upload_logs "/tmp/dnf.rpm.log", failok => 1;
    upload_logs "/tmp/dbus.log", failok => 1;

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
        # 0 means use console_login's default, non-zero values
        # passed to console_login
        timeout => 0,
        @_);
    if (get_var("SERIAL_CONSOLE")) {
        # select first virtio terminal, we rely on anaconda having run
        # a root shell on it for us
        select_console("virtio-console");
        # as we don't have any live image serial install tests, we
        # know we don't need to login
        return;
    }
    else {
        # tty3 has a shell on all f31+ installer and live images
        select_console "tty3-console";
    }
    console_login(user => "root", timeout => $args{timeout});
}

1;

# vim: set sw=4 et:
