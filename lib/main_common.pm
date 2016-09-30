package main_common;

use strict;

use base 'Exporter';
use Exporter;

use testapi;
our @EXPORT = qw/run_with_error_check check_type_string type_safely type_very_safely desktop_vt boot_to_login_screen console_login console_switch_layout/;

sub run_with_error_check {
    my ($func, $error_screen) = @_;
    die "Error screen appeared" if (check_screen $error_screen, 5);
    $func->();
    die "Error screen appeared" if (check_screen $error_screen, 5);
}

# type the string in sets of characters at a time (default 3), waiting
# for a screen change after each set. Intended to be safer when the VM
# is busy and regular type_string may overload the input buffer. Args
# passed along to `type_string`. Accepts additional args:
# `size` - size of character groups (default 3) - set to 1 for extreme
#          safety (but slower and more screenshotting)
sub check_type_string {
    my ($string, %args) = @_;
    $args{size} //= 3;

    # split string into an array of pieces of specified size
    # https://stackoverflow.com/questions/372370
    my @pieces = unpack("(a$args{size})*", $string);
    for my $piece (@pieces) {
        wait_screen_change { type_string($piece, %args); };
    }
}

# high-level 'type this string quite safely but reasonably fast'
# function whose specific implementation may vary
sub type_safely {
    my $string = shift;
    check_type_string($string, max_interval => 20);
    wait_still_screen 2;
}

# high-level 'type this string extremely safely and rather slow'
# function whose specific implementation may vary
sub type_very_safely {
    my $string = shift;
    check_type_string($string, size => 1, still => 5, max_interval => 1);
    wait_still_screen 5;
}

# Figure out what tty the desktop is on, switch to it. Assumes we're
# at a root console
sub desktop_vt {
    # use ps to find the tty of Xwayland or Xorg
    my $xout;
    # don't fail test if we don't find any process, just guess tty1
    eval { $xout = script_output 'ps -C Xwayland,Xorg -o tty --no-headers'; };
    my $tty = 1; # default
    while ($xout =~ /tty(\d)/g) {
        $tty = $1; # most recent match is probably best
    }
    send_key "ctrl-alt-f${tty}";
}

# Wait for login screen to appear. Handle the annoying GPU buffer
# problem where we see a stale copy of the login screen from the
# previous boot. Will suffer a ~30 second delay if there's a chance
# we're *already at* the expected login screen.
sub boot_to_login_screen {
    my %args = @_;
    $args{timeout} //= 300;
    # we may start at a screen that matches one of the needles; if so,
    # wait till we don't (e.g. when rebooting at end of live install,
    # we match text_console_login until the console disappears)
    my $count = 5;
    while (check_screen("login_screen", 3) && $count > 0) {
        sleep 5;
        $count -= 1;
    }
    assert_screen "login_screen", $args{timeout};
    if (match_has_tag "graphical_login") {
        wait_still_screen 10, 30;
        assert_screen "login_screen";
    }
}

# Switch keyboard layouts at a console
sub console_switch_layout {
    # switcher key combo differs between layouts, for console
    if (get_var("LANGUAGE", "") eq "russian") {
        send_key "ctrl-shift";
    }
}

# this subroutine handles logging in as a root/specified user into console
# it requires TTY to be already displayed (handled by the root_console()
# method of distribution classes)
sub console_login {
    my %args = (
        user => "root",
        password => get_var("ROOT_PASSWORD", "weakpassword"),
        @_);

    # There's a timing problem when we switch from a logged-in console
    # to a non-logged in console and immediately call this function;
    # if the switch lags a bit, this function will match one of the
    # logged-in needles for the console we switched from, and get out
    # of sync (e.g. https://openqa.stg.fedoraproject.org/tests/1664 )
    # To avoid this, we'll sleep a couple of seconds before starting
    sleep 2;

    my $good = "";
    my $bad = "";
    if ($args{user} eq "root") {
        $good = "root_console";
        $bad = "user_console";
    }
    else {
        $good = "user_console";
        $bad = "root_console";
    }

    if (check_screen $bad, 0) {
        # we don't want to 'wait' for this as it won't return
        script_run "exit", 0;
        sleep 2;
    }

    check_screen [$good, 'text_console_login'], 10;
    # if we're already logged in, all is good
    return if (match_has_tag $good);
    # if we see the login prompt, type the username
    type_string("$args{user}\n") if (match_has_tag 'text_console_login');
    check_screen [$good, 'console_password_required'], 30;
    # on a live image, just the user name will be enough
    return if (match_has_tag $good);
    # otherwise, type the password if we see the prompt
    if (match_has_tag 'console_password_required') {
        type_string "$args{password}";
        if (get_var("SWITCHED_LAYOUT") and $args{user} ne "root") {
            # see _do_install_and_reboot; when layout is switched
            # user password is doubled to contain both US and native
            # chars
            console_switch_layout;
            type_string "$args{password}";
            console_switch_layout;
        }
        send_key "ret";
    }
    # make sure we reached the console
    assert_screen($good, 30);
}
