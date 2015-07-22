package fedorabase;
use base 'basetest';

use testapi;

sub console_login {
    my $self = shift;
    my %args = (
        user => "root",
        password => get_var("ROOT_PASSWORD", "weakpassword"),
        check => 1,
        @_);

    my $good = "";
    my $bad = "";
    my $needuser = 1;
    my $needpass = 1;
    if ($args{user} eq "root") {
        $good = "root_console";
        $bad = "user_console";
    }
    else {
        $good = "user_console";
        $bad = "root_console";
    }

    for my $n (1 .. 10) {
        # This little loop should handle all possibilities quite
        # efficiently: already at a prompt (previously logged in, or
        # anaconda case), only need to enter username (live case),
        # need to enter both username and password (installed system
        # case). There are some annoying cases here involving delays
        # to various commands and the limitations of needles;
        # text_console_login also matches when the password prompt
        # is displayed (as the login prompt is still visible), and
        # both still match after login is complete, unless something
        # runs 'clear'. The sleeps and $needuser / $needpass attempt
        # to mitigate these problems.
        if (check_screen $good, 0) {
            return;
        }
        elsif (check_screen $bad, 0) {
            type_string "exit\n";
            sleep 2;
        }
        if ($needuser and check_screen "text_console_login", 0) {
            type_string "$args{user}\n";
            $needuser = 0;
            sleep 2;
        }
        elsif ($needpass and check_screen "console_password_required", 0) {
            type_string "$args{password}\n";
            $needpass = 0;
            # Sometimes login takes a bit of time, so add an extra sleep
            sleep 2;
        }

        sleep 1;
    }
    # If we got here we failed; if 'check' is set, die.
    $args{check} && die "Failed to reach console!"
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

1;

# vim: set sw=4 et:
