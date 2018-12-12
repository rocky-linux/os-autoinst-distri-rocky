package installedtest;
use base 'basetest';

# base class for tests that run on installed system

# should be used when with tests, where system is already installed, e. g all parts
# of upgrade tests, postinstall phases...

use testapi;
use utils;

sub root_console {
    # Switch to a default or specified TTY and log in as root.
    my $self = shift;
    my %args = (
        tty => 1, # what TTY to login to
        @_);

    send_key "ctrl-alt-f$args{tty}";
    console_login;
}

sub post_fail_hook {
    my $self = shift;

    if (check_screen 'emergency_rescue', 3) {
        my $password = get_var("ROOT_PASSWORD", "weakpassword");
        type_string "$password\n";
        # bring up network so we can upload logs
        assert_script_run "dhclient";
    }
    else {
        $self->root_console(tty=>6);
    }

    # We can't rely on tar being in minimal installs, but we also can't
    # rely on dnf always working (it fails in emergency mode, not sure
    # why), so try it, then check if we have tar
    script_run "dnf -y install tar", 180;

    # if we don't have tar or a network connection, we'll try and at
    # least send out *some* kinda info via the serial line
    my $hostip = testapi::host_ip();
    if ((script_run "rpm -q tar") || (script_run "ping -c 2 ${hostip}")) {
        script_run 'printf "\n** IP ADDR **\n" > /dev/' . $serialdev;
        script_run "ip addr > /dev/${serialdev} 2>&1";
        script_run 'printf "\n** IP ROUTE **\n" > /dev/' . $serialdev;
        script_run "ip route > /dev/${serialdev} 2>&1";
        script_run 'printf "\n** NETWORKMANAGER.SERVICE STATUS **\n" > /dev/' . $serialdev;
        script_run "systemctl --no-pager -l status NetworkManager.service > /dev/${serialdev} 2>&1";
        script_run 'printf "\n** JOURNAL **\n" > /dev/' . $serialdev;
        script_run "journalctl -b --no-pager > /dev/${serialdev}";
        return;
    }

    # Note: script_run returns the exit code, so the logic looks weird.
    # We're testing that the directory exists and contains something.
    unless (script_run 'test -n "$(ls -A /var/tmp/abrt)" && cd /var/tmp/abrt && tar czvf tmpabrt.tar.gz *') {
        upload_logs "/var/tmp/abrt/tmpabrt.tar.gz";
    }

    unless (script_run 'test -n "$(ls -A /var/spool/abrt)" && cd /var/spool/abrt && tar czvf spoolabrt.tar.gz *') {
        upload_logs "/var/spool/abrt/spoolabrt.tar.gz";
    }

    # upload any core dump files caught by coredumpctl
    unless (script_run 'test -n "$(ls -A /var/lib/systemd/coredump)" && cd /var/lib/systemd/coredump && tar czvf coredump.tar.gz *') {
        upload_logs "/var/lib/systemd/coredump/coredump.tar.gz";
    }

    # Upload /var/log
    # lastlog can mess up tar sometimes and it's not much use
    unless (script_run "tar czvf /tmp/var_log.tar.gz --exclude='lastlog' /var/log") {
        upload_logs "/tmp/var_log.tar.gz";
    }

    # Sometimes useful for diagnosing FreeIPA issues
    upload_logs "/etc/nsswitch.conf", failok=>1;
}

1;

# vim: set sw=4 et:
