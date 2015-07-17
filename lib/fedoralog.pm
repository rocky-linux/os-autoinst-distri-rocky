package fedoralog;
use base 'basetest';

use testapi;

sub login_as_root {
    my $self = shift;
    my $tty = shift || 1;
    my $password = get_var("ROOT_PASSWORD", "weakpassword");

    send_key "ctrl-alt-f$tty";
    assert_screen "text_console_login", 20;

    type_string "root";
    send_key "ret";
    assert_screen "console_password_required", 10;
    type_string $password;
    send_key "ret";

    assert_screen "root_logged_in", 10;
}

sub boot_to_login_screen {
    my $self = shift;
    my $boot_done_screen = shift;
    my $stillscreen = shift || 10;
    my $timeout = shift || 60;

    wait_still_screen $stillscreen, $timeout;

    if ($boot_done_screen ne "") {
        assert_screen $boot_done_screen;
    }
}

sub post_fail_hook {
    my $self = shift;

    $self->login_as_root(2);

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
