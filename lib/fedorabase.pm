package fedorabase;
use base 'basetest';
use lockapi;

# base class for all Fedora tests

# use this class when using other base class doesn't make sense

use testapi;

# this subroutine handles logging in as a root/specified user into console
# it requires TTY to be already displayed (handled by the root_console() method of subclasses)
sub console_login {
    my $self = shift;
    my %args = (
        user => "root",
        password => get_var("ROOT_PASSWORD", "weakpassword"),
        check => 1,
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
            script_run "exit";
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

sub do_bootloader {
    # Handle bootloader screen. 'bootloader' is syslinux or grub.
    # 'uefi' is whether this is a UEFI install, will get_var UEFI if
    # not explicitly set. 'postinstall' is whether we're on an
    # installed system or at the installer (this matters for how many
    # times we press 'down' to find the kernel line when typing args).
    # 'args' is a string of extra kernel args, if desired. 'mutex' is
    # a parallel test mutex lock to wait for before proceeding, if
    # desired. 'first' is whether to hit 'up' a couple of times to
    # make sure we boot the first menu entry.
    my ($self, $postinstall, $args, $mutex, $first, $bootloader, $uefi) = @_;
    $uefi //= get_var("UEFI");
    $postinstall //= 0;
    # if not postinstall and not UEFI, syslinux
    $bootloader //= ($uefi || $postinstall) ? "grub" : "syslinux";
    $args //= "";
    $mutex //= "";
    $first //= 1;
    if ($uefi) {
        # we don't just tag all screens with 'bootloader' because we
        # want to be sure we actually did a UEFI boot
        assert_screen "bootloader_uefi", 30;
    } else {
        assert_screen "bootloader", 30;
    }
    if ($mutex) {
        # cancel countdown
        send_key "left";
        mutex_lock $mutex;
        mutex_unlock $mutex;
    }
    if ($first) {
        # press up a couple of times to make sure we're at first entry
        send_key "up";
        send_key "up";
    }
    if ($args) {
        if ($bootloader eq "syslinux") {
            send_key "tab";
        }
        else {
            send_key "e";
            # ternary: 13 'downs' to reach the kernel line for installed
            # system, 2 for UEFI installer
            my $presses = $postinstall ? 13 : 2;
            foreach my $i (1..$presses) {
                send_key "down";
            }
            send_key "end";
        }
        type_string " $args";
    }
    # ctrl-X boots from grub editor mode
    send_key "ctrl-x";
    # return boots all other cases
    send_key "ret";
}

sub boot_to_login_screen {
    my $self = shift;
    my $boot_done_screen = shift; # what to expect when system is booted (e. g. GDM), can be ""
    my $stillscreen = shift || 10;
    my $timeout = shift || 60;

    wait_still_screen $stillscreen, $timeout;

    if ($boot_done_screen ne "") {
        assert_screen $boot_done_screen;
    }
}

sub get_milestone {
    my $self = shift;
    # FIXME: we don't know how to do this with Pungi 4 yet.
    return '';
}

sub clone_host_resolv {
    # this is pretty crazy, but SUSE do almost the same thing...
    # it's for openvswitch jobs to clone the host's resolv.conf, so
    # we don't have to hard code 8.8.8.8 or have the templates pass
    # in an address or something
    my $self = shift;
    my $resolv = '';
    open(FH, '<', "/etc/resolv.conf");
    while (<FH>) {
        $resolv .= $_;
    }
    assert_script_run "printf '$resolv' > /etc/resolv.conf";
    # for debugging...
    assert_script_run "cat /etc/resolv.conf";
}

1;

# vim: set sw=4 et:
