package installedtest;

use strict;

use base 'basetest';

# base class for tests that run on installed system

# should be used when with tests, where system is already installed, e. g all parts
# of upgrade tests, postinstall phases...

use testapi qw(is_serial_terminal :DEFAULT select_console);
use utils;

sub root_console {
    # Switch to a default or specified TTY and log in as root.
    my $self = shift;
    my %args = (
        tty => 1,    # what TTY to login to
        @_);
    if (get_var("SERIAL_CONSOLE")) {
        # select the first virtio terminal, for now we assume we can
        # always use that (we may have to make this smarter in future)
        select_console("virtio-console");
    }
    else {
        # For normal terminal emulation, use key combo to reach a tty
        select_console "tty$args{tty}-console";
    }
    console_login;    # Do the login.
}

sub post_fail_hook {
    my $self = shift;

    if (check_screen ['emergency_rescue', 'emergency_rescue_nopassword'], 3) {
        if (match_has_tag 'emergency_rescue') {
            my $password = get_var("ROOT_PASSWORD", "weakpassword");
            type_string "$password";
        }
        send_key 'ret';
        # bring up network so we can upload logs
        assert_script_run "dhclient";
    }
    else {
        $self->root_console(tty => 6);
        # fix up keyboard layout, if we failed before the test did this
        # itself; if it's already been done, should be safe, will just
        # fail and carry on
        console_loadkeys_us;
    }

    # if we're in dracut, do things different
    my $dracut = 0;
    if (check_screen "root_console_dracut", 0) {
        $dracut = 1;
        script_run "dhclient";
    }

    # We can't rely on tar being in minimal installs, but we also can't
    # rely on dnf always working (it fails in emergency mode, not sure
    # why), so try it. if we don't get a return code, process may be
    # stuck waiting on network or something, so hit ctrl-c
    unless (script_run "dnf -y install tar", 180) {
        unless (is_serial_terminal) {
            send_key "ctrl-c";
        }
    }

    # if we don't have tar or a network connection, we'll try and at
    # least send out *some* kinda info via the serial line
    my $hostip = testapi::host_ip();
    if ((script_run "rpm -q tar") || (script_run "ping -c 2 ${hostip}")) {
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
        script_run 'printf "\n** JOURNAL **\n" > /dev/' . $serialdev;
        script_run "journalctl -b --no-pager > /dev/${serialdev}";
        return;
    }

    if ($dracut) {
        upload_logs "/run/initramfs/rdsosreport.txt", failok => 1;
        # that's all that's really useful, so...
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

    # upload bind log (for FreeIPA server test)
    unless (script_run 'test -f /var/named/data/named.run') {
        upload_logs "/var/named/data/named.run";
    }

    # update PostgreSQL initialization log (for database_server test)
    unless (script_run 'test -f /var/lib/pgsql/initdb_postgresql.log') {
        upload_logs "/var/lib/pgsql/initdb_postgresql.log";
    }

    # Upload /var/log
    # lastlog can mess up tar sometimes and it's not much use
    unless (script_run "tar czvf /tmp/var_log.tar.gz --exclude='lastlog' /var/log") {
        upload_logs "/tmp/var_log.tar.gz";
    }

    # Sometimes useful for diagnosing FreeIPA issues
    upload_logs "/etc/nsswitch.conf", failok => 1;

    if (get_var("FLAVOR") eq "updates-everything-boot-iso") {
        # for installer creation test
        script_run "df -h";
        upload_logs "/root/imgbuild/pylorax.log", failok => 1;
        upload_logs "/root/imgbuild/lorax.log", failok => 1;
        upload_logs "/root/imgbuild/program.log", failok => 1;
    }

    if (get_var("TEST") eq "live_build") {
        # for live image creation test
        script_run "df -h";
        script_run 'mock -r openqa --chroot "ls -l /chroot_tmpdir/lmc-logs/anaconda"';
        unless (script_run "mock -r openqa --copyout /chroot_tmpdir/lmc-logs/livemedia-out.log .") {
            upload_logs "livemedia-out.log";
        }
        unless (script_run "mock -r openqa --copyout /chroot_tmpdir/lmc-logs/anaconda/ anaconda") {
            assert_script_run "tar cvzf anaconda.tar.gz anaconda/";
            upload_logs "anaconda.tar.gz";
        }
    }
}

# For update tests, let's do the update package info log stuff,
# it may be useful for diagnosing the cause of the failure
advisory_get_installed_packages;
advisory_check_nonmatching_packages(fatal => 0);

1;

# vim: set sw=4 et:
