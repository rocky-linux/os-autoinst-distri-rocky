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
            # we don't want to 'wait' for this as it won't return
            script_run "exit", 0;
            sleep 2;
        }
        if ($needuser and check_screen "text_console_login", 0) {
            type_string "$args{user}\n";
            $needuser = 0;
            sleep 2;
        }
        elsif ($needpass and check_screen "console_password_required", 0) {
            type_string "$args{password}";
            if (get_var("SWITCHED_LAYOUT") and $args{user} ne "root") {
                # see _do_install_and_reboot; when layout is switched
                # user password is doubled to contain both US and native
                # chars
                $self->console_switch_layout();
                type_string "$args{password}";
                $self->console_switch_layout();
            }
            send_key "ret";
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
    # make sure we boot the first menu entry. 'timeout' is how long to
    # wait for the bootloader screen.
    my $self = shift;
    my %args = (
        postinstall => 0,
        params => "",
        mutex => "",
        first => 1,
        timeout => 30,
        uefi => get_var("UEFI"),
        @_
    );
    # if not postinstall and not UEFI, syslinux
    $args{bootloader} //= ($args{uefi} || $args{postinstall}) ? "grub" : "syslinux";
    if ($args{uefi}) {
        # we use the firmware-type specific tags because we want to be
        # sure we actually did a UEFI boot
        assert_screen "bootloader_uefi", $args{timeout};
    } else {
        assert_screen "bootloader_bios", $args{timeout};
    }
    if ($args{mutex}) {
        # cancel countdown
        send_key "left";
        mutex_lock $args{mutex};
        mutex_unlock $args{mutex};
    }
    if ($args{first}) {
        # press up a couple of times to make sure we're at first entry
        send_key "up";
        send_key "up";
    }
    if ($args{params}) {
        if ($args{bootloader} eq "syslinux") {
            send_key "tab";
        }
        else {
            send_key "e";
            # ternary: 13 'downs' to reach the kernel line for installed
            # system, 2 for UEFI installer
            my $presses = $args{postinstall} ? 13 : 2;
            foreach my $i (1..$presses) {
                send_key "down";
            }
            send_key "end";
        }
        type_string " $args{params}";
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

sub clone_host_file {
    # copy a given file from the host into the guest. Mainly used
    # for networking config on tap tests. this is pretty crazy, but
    # SUSE do almost the same thing...
    my $self = shift;
    my $file = shift;
    my $text = '';
    open(my $fh, '<', $file);
    while (<$fh>) {
        $text .= $_;
    }
    assert_script_run "printf '$text' > $file";
    # for debugging...
    assert_script_run "cat $file";
}

sub setup_tap_static {
    # this is a common thing for tap tests, where we set up networking
    # for the system with a static IP address and possibly a specific
    # hostname
    my $self = shift;
    my $ip = shift;
    my $hostname = shift || "";
    if ($hostname) {
        # assigning output of split to a single-item array gives us just
        # the first split
        my ($short) = split(/\./, $hostname);
        # set hostname
        assert_script_run "hostnamectl set-hostname $hostname";
        # add entry to /etc/hosts
        assert_script_run "echo '$ip $hostname $short' >> /etc/hosts";
    }
    # bring up network. DEFROUTE is *vital* here
    assert_script_run "printf 'DEVICE=eth0\nBOOTPROTO=none\nIPADDR=$ip\nGATEWAY=10.0.2.2\nPREFIX=24\nDEFROUTE=yes' > /etc/sysconfig/network-scripts/ifcfg-eth0";
    script_run "systemctl restart NetworkManager.service";
}

sub console_switch_layout {
    # switcher key combo differs between layouts, for console
    my $self = shift;
    if (get_var("LANGUAGE", "") eq "russian") {
        send_key "ctrl-shift";
    }
}

sub get_host_dns {
    # get DNS server addresses from the host
    my @forwards;
    open(FH, '<', "/etc/resolv.conf");
    while (<FH>) {
        if ($_ =~ m/^nameserver +(.+)/) {
            push @forwards, $1;
        }
    }
    return @forwards;
}

sub boot_decrypt {
    # decrypt storage during boot; arg is timeout (in seconds)
    my $self = shift;
    my $timeout = shift || 60;
    assert_screen "boot_enter_passphrase", $timeout; #
    type_string get_var("ENCRYPT_PASSWORD");
    send_key "ret";
}

1;

# vim: set sw=4 et:
