package utils;

use strict;

use base 'Exporter';
use Exporter;

use lockapi;
use testapi;
our @EXPORT = qw/run_with_error_check type_safely type_very_safely desktop_vt boot_to_login_screen console_login console_switch_layout desktop_switch_layout console_loadkeys_us do_bootloader get_milestone boot_decrypt check_release menu_launch_type start_cockpit repo_setup/;

sub run_with_error_check {
    my ($func, $error_screen) = @_;
    die "Error screen appeared" if (check_screen $error_screen, 5);
    $func->();
    die "Error screen appeared" if (check_screen $error_screen, 5);
}

# high-level 'type this string quite safely but reasonably fast'
# function whose specific implementation may vary
sub type_safely {
    my $string = shift;
    type_string($string, wait_screen_change => 3, max_interval => 20);
    wait_still_screen 2;
}

# high-level 'type this string extremely safely and rather slow'
# function whose specific implementation may vary
sub type_very_safely {
    my $string = shift;
    type_string($string, wait_screen_change => 1, max_interval => 1);
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

# switch to 'native' or 'ascii' input method in a graphical desktop
# usually switched configs have one mode for inputting ascii-ish
# characters (which may be 'us' keyboard layout, or a local layout for
# inputting ascii like 'jp') and one mode for inputting native
# characters (which may be another keyboard layout, like 'ru', or an
# input method for more complex languages)
# 'environment' can be a desktop name or 'anaconda' for anaconda
# if not set, will use get_var('DESKTOP') or default 'anaconda'
sub desktop_switch_layout {
    my ($layout, $environment) = @_;
    $layout //= 'ascii';
    $environment //= get_var("DESKTOP", "anaconda");
    # if already selected, we're good
    return if (check_screen "${environment}_layout_${layout}", 3);
    # otherwise we need to switch
    my $switcher = "alt-shift";  # anaconda
    $switcher = "super-spc" if $environment eq 'gnome';
    # KDE? not used yet
    send_key $switcher;
    assert_screen "${environment}_layout_${layout}", 3;
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

# load US layout (from a root console)
sub console_loadkeys_us {
    if (get_var('LANGUAGE') eq 'french') {
        script_run "loqdkeys us", 0;
    }
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

sub get_milestone {
    # FIXME: we don't know how to do this with Pungi 4 yet.
    return '';
}

sub boot_decrypt {
    # decrypt storage during boot; arg is timeout (in seconds)
    my $timeout = shift || 60;
    assert_screen "boot_enter_passphrase", $timeout; #
    type_string get_var("ENCRYPT_PASSWORD");
    send_key "ret";
}

sub check_release {
    # Checks whether the installed release matches a given value. E.g.
    # `check_release(23)` checks whether the installed system is
    # Fedora 23. The value can be 'Rawhide' or a Fedora release
    # number; often you will want to use `get_var('VERSION')`. Expects
    # a console prompt to be active when it is called.
    my $self = shift;
    my $release = shift;
    my $check_command = "grep SUPPORT_PRODUCT_VERSION /usr/lib/os.release.d/os-release-fedora";
    validate_script_output $check_command, sub { $_ =~ m/REDHAT_SUPPORT_PRODUCT_VERSION=$release/ };
}

sub menu_launch_type {
    # Launch an application in a graphical environment, by opening a
    # launcher, typing the specified string and hitting enter. Pass
    # the string to be typed to launch whatever it is you want.
    my $self = shift;
    my $app = shift;
    # super does not work on KDE, because fml
    send_key 'alt-f1';
    # srsly KDE y u so slo
    wait_still_screen 3;
    type_very_safely $app;
    send_key 'ret';
}

sub start_cockpit {
    # Starting from a console, get to a browser with Cockpit (running
    # on localhost) shown. If $login is truth-y, also log in. Assumes
    # X and Firefox are installed.
    my $self = shift;
    my $login = shift || 0;
    # run firefox directly in X as root. never do this, kids!
    type_string "startx /usr/bin/firefox -width 1024 -height 768 http://localhost:9090\n";
    assert_screen "cockpit_login";
    wait_still_screen 5;
    if ($login) {
        type_safely "root";
        wait_screen_change { send_key "tab"; };
        type_safely get_var("ROOT_PASSWORD", "weakpassword");
        send_key "ret";
        assert_screen "cockpit_main";
        # wait for any animation or other weirdness
        # can't use wait_still_screen because of that damn graph
        sleep 3;
    }
}

sub repo_setup {
    # disable updates-testing and updates and use the compose location
    # as the target for fedora and rawhide rather than mirrorlist, so
    # tools see only packages from the compose under test
    my $location = get_var("LOCATION");
    assert_script_run 'dnf config-manager --set-disabled updates-testing updates';
    # we use script_run here as the rawhide repo file won't always exist
    # and we don't want to bother testing or predicting its existence;
    # assert_script_run doesn't buy you much with sed anyway as it'll
    # return 0 even if it replaced nothing
    script_run "sed -i -e 's,^metalink,#metalink,g' -e 's,^#baseurl.*basearch,baseurl=${location}/Everything/\$basearch,g' /etc/yum.repos.d/{fedora,fedora-rawhide}.repo", 0;
    script_run "cat /etc/yum.repos.d/{fedora,fedora-rawhide}.repo", 0;
}

