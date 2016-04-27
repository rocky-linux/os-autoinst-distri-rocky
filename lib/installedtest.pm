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

1;

# vim: set sw=4 et:
