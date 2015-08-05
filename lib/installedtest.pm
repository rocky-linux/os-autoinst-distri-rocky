package fedoralog;
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

    # Upload all ABRT logs
    type_string "cd /var/tmp/abrt && tar czvf abrt.tar.gz *";
    send_key "ret";
    upload_logs "/var/tmp/abrt/abrt.tar.gz";

    # Upload /var/log
    type_string "tar czvf /tmp/var_log.tar.gz /var/log";
    send_key "ret";
    upload_logs "/tmp/var_log.tar.gz";
}

1;

# vim: set sw=4 et:
