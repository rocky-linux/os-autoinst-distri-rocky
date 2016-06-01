package installedtest;
use base 'fedorabase';

# base class for tests that run on installed system

# should be used when with tests, where system is already installed, e. g all parts
# of upgrade tests, postinstall phases...

use testapi;

sub root_console {
    my $self = shift;
    my %args = (
        tty => 1, # what TTY to login to
        check => 1, # whether to fail when console wasn't reached
        @_);

    send_key "ctrl-alt-f$args{tty}";
    $self->console_login(check=>$args{check});
}

sub post_fail_hook {
    my $self = shift;

    $self->root_console(tty=>2);

    # If /var/tmp/abrt directory isn't empty (ls doesn't return empty string)
    my $vartmp = script_output "ls /var/tmp/abrt";
    if ($vartmp ne '') {
        # Upload all ABRT logs
        script_run "cd /var/tmp/abrt && tar czvf abrt.tar.gz *";
        upload_logs "/var/tmp/abrt/abrt.tar.gz";
    }

    # Upload /var/log
    script_run "tar czvf /tmp/var_log.tar.gz /var/log";
    upload_logs "/tmp/var_log.tar.gz";
}

sub check_release {
    my $self = shift;
    my $release = shift;
    my $check_command = "grep SUPPORT_PRODUCT_VERSION /usr/lib/os.release.d/os-release-fedora";
    validate_script_output $check_command, sub { $_ =~ m/REDHAT_SUPPORT_PRODUCT_VERSION=$release/ };
}

sub menu_launch_type {
    my $self = shift;
    my $app = shift;
    # super does not work on KDE, because fml
    send_key 'alt-f1';
    # srsly KDE y u so slo
    wait_still_screen 3;
    type_string "$app";
    wait_still_screen 3;
    send_key 'ret';
}

sub start_cockpit {
    my $self = shift;
    my $login = shift || 0;
    # run firefox directly in X as root. never do this, kids!
    type_string "startx /usr/bin/firefox\n";
    assert_screen "firefox";
    # open a new tab so we don't race with the default page load
    # (also focuses the location bar for us)
    send_key "ctrl-t";
    type_string "http://localhost:9090";
    # firefox's stupid 'smart' url bar is a pain. wait for things to settle.
    wait_still_screen 3;
    send_key "ret";
    assert_screen "cockpit_login";
    if ($login) {
        type_string "root";
        send_key "tab";
        type_string get_var("ROOT_PASSWORD", "weakpassword");
        send_key "ret";
        assert_screen "cockpit_main";
    }
}

1;

# vim: set sw=4 et:
