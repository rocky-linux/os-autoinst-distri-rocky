package utils;

use strict;

use base 'Exporter';
use Exporter;

use lockapi;
use testapi;
our @EXPORT = qw/run_with_error_check type_safely type_very_safely desktop_vt boot_to_login_screen console_login console_switch_layout desktop_switch_layout console_loadkeys_us do_bootloader get_milestone boot_decrypt check_release menu_launch_type start_cockpit repo_setup gnome_initial_setup anaconda_create_user check_desktop_clean/;

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

# this is used at the end of console_login to check if we got a prompt
# indicating that we got a bash shell, but sourcing of /etc/bashrc
# failed (the prompt looks different in this case). We treat this as
# a soft failure.
sub _console_login_finish {
    if (match_has_tag "bash_noprofile") {
        record_soft_failure "It looks like profile sourcing failed";
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
    # To avoid this, we'll sleep a few seconds before starting
    sleep 4;

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
    if (match_has_tag $good) {
        _console_login_finish();
        return;
    }
    # if we see the login prompt, type the username
    type_string("$args{user}\n") if (match_has_tag 'text_console_login');
    check_screen [$good, 'console_password_required'], 30;
    # on a live image, just the user name will be enough
    if (match_has_tag $good) {
        _console_login_finish();
        return;
    }
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
    _console_login_finish();
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
        ofw => get_var("OFW"),
        @_
    );
    # if not postinstall not UEFI and not ofw, syslinux
    $args{bootloader} //= ($args{uefi} || $args{postinstall} || $args{ofw}) ? "grub" : "syslinux";
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
            # 2 'downs' to reach the kernel line for UEFI installer,
            # 13 'downs' on installed x86_64. 12 'downs' on installed
            # ppc64, because it doesn't have a 'set gfxpayload=keep'
            # line. installed aarch64 is tricky: it should be 13, I
            # think - it has a set gfxpayload=keep line - but it seems
            # that on F27 installs (i.e. support_server) there is a
            # 'set root' line, but on F28+ installs there is not, so
            # the count is 12. So we have to do something gross.
            my $presses = 2;
            if ($args{postinstall}) {
                if (get_var('OFW') || (get_var('ARCH') eq 'aarch64' && get_var('TEST') ne 'support_server')) {
                    $presses = 12;
                } else {
                    $presses = 13;
                }
            }
            foreach my $i (1..$presses) {
                sleep 1; # seems to have missed one down if too fast.
                send_key "down";
            }
            send_key "end";
        }
        # Change type_string by type_safely because keyboard polling
        # in SLOF usb-xhci driver failed sometimes in powerpc
        type_safely " $args{params}";
    }
    save_screenshot; # for debug purpose
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
    my $release = shift;
    my $check_command = "grep SUPPORT_PRODUCT_VERSION /usr/lib/os.release.d/os-release-fedora";
    validate_script_output $check_command, sub { $_ =~ m/REDHAT_SUPPORT_PRODUCT_VERSION=$release/ };
}

sub menu_launch_type {
    # Launch an application in a graphical environment, by opening a
    # launcher, typing the specified string and hitting enter. Pass
    # the string to be typed to launch whatever it is you want.
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
    my $login = shift || 0;
    # https://bugzilla.redhat.com/show_bug.cgi?id=1439429
    assert_script_run "sed -i -e 's,enable_xauth=1,enable_xauth=0,g' /usr/bin/startx";
    # run firefox directly in X as root. never do this, kids!
    type_string "startx /usr/bin/firefox -width 1024 -height 768 http://localhost:9090\n";
    assert_screen "cockpit_login";
    # this happened on early Modular Server composes...
    record_soft_failure "Unbranded Cockpit" if (match_has_tag "cockpit_login_unbranded");
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

sub _repo_setup_compose {
    # Appropriate repo setup steps for testing a compose
    # disable updates-testing and updates and use the compose location
    # as the target for fedora and rawhide rather than mirrorlist, so
    # tools see only packages from the compose under test
    my $location = get_var("LOCATION");
    return unless $location;
    assert_script_run 'dnf config-manager --set-disabled updates-testing updates';
    # script_run returns the exit code, so 'unless' here means 'if the file exists'
    unless (script_run 'test -f /etc/yum.repos.d/fedora-updates-modular.repo') {
            assert_script_run 'dnf config-manager --set-disabled updates-testing-modular updates-modular';
    }
    # we use script_run here as the rawhide and modular repo files
    # won't always exist and we don't want to bother testing or
    # predicting their existence; assert_script_run doesn't buy you
    # much with sed as it'll return 0 even if it replaced nothing
    script_run "sed -i -e 's,^metalink,#metalink,g' -e 's,^#baseurl.*basearch,baseurl=${location}/Everything/\$basearch,g' -e 's,^#baseurl.*source,baseurl=${location}/Everything/source,g' /etc/yum.repos.d/{fedora,fedora-rawhide}.repo", 0;
    script_run "sed -i -e 's,^metalink,#metalink,g' -e 's,^#baseurl.*basearch,baseurl=${location}/Modular/\$basearch,g' -e 's,^#baseurl.*source,baseurl=${location}/Modular/source,g' /etc/yum.repos.d/{fedora-modular,fedora-rawhide-modular}.repo", 0;
    # this is just for debugging
    script_run "cat /etc/yum.repos.d/{fedora,fedora-rawhide,fedora-modular,fedora-rawhide-modular}.repo", 0;
}

sub _repo_setup_updates_development {
    # Fix URL for fedora.repo if this is a development release
    # This is rather icky, but I can't think of any better way
    # The problem is that the 'baseurl' line in fedora.repo is
    # always left as the correct URL for a *stable* release, we
    # don't change it to the URL for a Branched release while the
    # release is Branched, as it's too much annoying package work
    assert_script_run "sed -i -e 's,/releases/,/development/,g' /etc/yum.repos.d/fedora.repo";
    # Disable updates-testing so other bad updates don't break us
    assert_script_run "dnf config-manager --set-disabled updates-testing";
    # https://pagure.io/fedora-repos/issue/70
    # this is the easiest workaround, it's not wrong as the repo
    # is empty for branched anyway
    assert_script_run "dnf config-manager --set-disabled updates";
    # same for Modular, if appropriate
    unless (script_run 'test -f /etc/yum.repos.d/fedora-updates-modular.repo') {
        assert_script_run "sed -i -e 's,/releases/,/development/,g' /etc/yum.repos.d/fedora-modular.repo";
        assert_script_run "dnf config-manager --set-disabled updates-testing-modular";
        assert_script_run "dnf config-manager --set-disabled updates-modular";
    }
}

sub _repo_setup_updates {
    # Appropriate repo setup steps for testing a Bodhi update
    # Check if we already ran, bail if so
    return unless script_run "test -f /etc/yum.repos.d/advisory.repo";
    # Use baseurl not metalink so we don't hit the timing issue where
    # the infra repo is updated but mirrormanager metadata checksums
    # have not been updated, and the infra repo is rejected as its
    # metadata checksum isn't known to MM
    assert_script_run "sed -i -e 's,^metalink,#metalink,g' -e 's,^#baseurl,baseurl,g' /etc/yum.repos.d/fedora*.repo";
    if (get_var("OFW")) {
        # the uncommented baseurl line must be changed for PowerPC
        # from download.fedoraproject.org/pub/fedora/linux/...
        # to   download.fedoraproject.org/pub/fedora-secondary/...
        script_run "sed -i -e 's,/pub/fedora/linux/,/pub/fedora-secondary/,g' /etc/yum.repos.d/fedora*.repo", 0;
    }
    # for non-upgrade tests, we want to do the 'development' changes
    # *before* we set up the update repo...
    _repo_setup_updates_development if (get_var("DEVELOPMENT") &! get_var("UPGRADE"));
    # Set up an additional repo containing the update packages. We do
    # this rather than simply running a one-time update because it may
    # be the case that a package from the update isn't installed *now*
    # but will be installed by one of the tests; by setting up a repo
    # containing the update and enabling it here, we ensure all later
    # 'dnf install' calls will get the packages from the update.
    assert_script_run "mkdir -p /opt/update_repo";
    assert_script_run "cd /opt/update_repo";
    assert_script_run "dnf -y install bodhi-client git createrepo koji", 300;
    # download the packages
    my $version = lc(get_var("VERSION"));
    if ($version eq 'rawhide' || $version > 25) {
        # bodhi client 2.x
        assert_script_run "bodhi updates download --updateid " . get_var("ADVISORY"), 600;
    }
    else {
        # bodhi client 0.9
        # use git python-fedora for
        # https://github.com/fedora-infra/python-fedora/pull/192
        # until packages with that fix are pushed stable
        assert_script_run "git clone https://github.com/fedora-infra/python-fedora.git";
        assert_script_run "PYTHONPATH=python-fedora/ bodhi -D " . get_var("ADVISORY"), 600;
    }
    # for upgrade tests, we want to do the 'development' changes *after*
    # we set up the update repo
    _repo_setup_updates_development if (get_var("DEVELOPMENT") && get_var("UPGRADE"));
    # log the exact packages in the update at test time, with their
    # source packages and epochs. log is uploaded by _advisory_update
    # and used for later comparison by _advisory_post
    assert_script_run 'rpm -qp *.rpm --qf "%{SOURCERPM} %{EPOCH} %{NAME}-%{VERSION}-%{RELEASE}\n" | sort -u > /var/log/updatepkgs.txt';
    # create the repo metadata
    assert_script_run "createrepo .";
    # write a repo config file
    assert_script_run 'printf "[advisory]\nname=Advisory repo\nbaseurl=file:///opt/update_repo\nenabled=1\nmetadata_expire=3600\ngpgcheck=0" > /etc/yum.repos.d/advisory.repo';
    # run an update now (except for upgrade tests)
    script_run "dnf -y update", 600 unless (get_var("UPGRADE"));
}

sub repo_setup {
    # Run the appropriate sub-function for the job
    get_var("ADVISORY") ? _repo_setup_updates : _repo_setup_compose;
    # This repo does not always exist for Rawhide or Branched, and
    # some things (at least realmd) try to update the repodata for
    # it even though it is disabled, and fail. At present none of the
    # tests needs it, so let's just unconditionally nuke it.
    assert_script_run "rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo";
}

sub gnome_initial_setup {
    # Handle gnome-initial-setup, with variations for the pre-login
    # mode (when no user was created during install) and post-login
    # mode (when user was created during install)
    my %args = (
        prelogin => 0,
        timeout => 120,
        @_
    );
    my $version = lc(get_var("VERSION"));
    # the pages we *may* need to click 'next' on. *NOTE*: 'language'
    # is the 'welcome' page, and is in fact never truly skipped; if
    # it's configured to be skipped, it just shows without the language
    # selection widget (so it's a bare 'welcome' page). Current openQA
    # tests never see 'eula' or 'network'. You can find the upstream
    # list in gnome-initial-setup/gnome-initial-setup.c , and the skip
    # config file for Fedora is vendor.conf in the package repo.
    my @nexts = ('language', 'keyboard', 'privacy', 'timezone', 'software');
    # now, we're going to figure out how many of them this test will
    # *actually* see...
    if ($args{prelogin}) {
        # 'language', 'keyboard' and 'timezone' are skipped on F28+ in
        # the 'new user' mode by
        # https://fedoraproject.org//wiki/Changes/ReduceInitialSetupRedundancy
        # https://bugzilla.redhat.com/show_bug.cgi?id=1474787 ,
        # except 'language' is never *really* skipped (see above)
        @nexts = grep {$_ ne 'keyboard'} @nexts if ($version eq 'rawhide' || $version > 27);
        @nexts = grep {$_ ne 'timezone'} @nexts if ($version eq 'rawhide' || $version > 27);
    }
    else {
        # 'timezone' and 'software' are suppressed for the 'existing user'
        # form of g-i-s
        @nexts = grep {$_ ne 'software'} @nexts;
        @nexts = grep {$_ ne 'timezone'} @nexts;
    }
    # 'additional software sources' screen does not display on F28+:
    # https://bugzilla.gnome.org/show_bug.cgi?id=794825
    @nexts = grep {$_ ne 'software'} @nexts if ($version eq 'rawhide' || $version > 27);

    assert_screen "next_button", $args{timeout};
    # wait a bit in case of animation
    wait_still_screen 3;
    # GDM 3.24.1 dumps a cursor in the middle of the screen here...
    mouse_hide if ($args{prelogin});
    for my $n (1..scalar(@nexts)) {
        # click 'Next' $nexts times, moving the mouse to avoid
        # highlight problems, sleeping to give it time to get
        # to the next screen between clicks
        mouse_set(100, 100);
        wait_screen_change { assert_and_click "next_button"; };
        # for Japanese, we need to workaround a bug on the keyboard
        # selection screen
        if ($n == 1 && get_var("LANGUAGE") eq 'japanese') {
            if (!check_screen 'initial_setup_kana_kanji_selected', 5) {
                record_soft_failure 'kana kanji not selected: bgo#776189';
                assert_and_click 'initial_setup_kana_kanji';
            }
        }
    }
    # click 'Skip' one time (this is the 'goa' screen)
    mouse_set(100,100);
    wait_screen_change { assert_and_click "skip_button"; };
    send_key "ret";
    if ($args{prelogin}) {
        # create user
        my $user_login = get_var("USER_LOGIN") || "test";
        my $user_password = get_var("USER_PASSWORD") || "weakpassword";
        type_very_safely $user_login;
        wait_screen_change { assert_and_click "next_button"; };
        type_very_safely $user_password;
        send_key "tab";
        type_very_safely $user_password;
        wait_screen_change { assert_and_click "next_button"; };
        send_key "ret";
    }
    else {
        # wait for the stupid 'help' screen to show and kill it
        if (check_screen "getting_started") {
            send_key "alt-f4";
            wait_still_screen 5;
        }
        else {
            record_soft_failure "'getting started' missing (probably BGO#790811)";
        }
        # don't do it again on second load
    }
    set_var("_setup_done", 1);
}

sub _type_user_password {
    # convenience function used by anaconda_create_user, not meant
    # for direct use
    my $user_password = get_var("USER_PASSWORD") || "weakpassword";
    if (get_var("SWITCHED_LAYOUT")) {
        # we double the password, the second time using the native
        # layout, so the password has both ASCII and native characters
        desktop_switch_layout "ascii", "anaconda";
        type_very_safely $user_password;
        desktop_switch_layout "native", "anaconda";
        type_very_safely $user_password;
    }
    else {
        type_very_safely $user_password;
    }
}

sub anaconda_create_user {
    # Create a user, in the anaconda interface. This is here because
    # the same code works both during install and for initial-setup,
    # which runs post-install, so we can share it.
    my %args = (
        timeout => 90,
        @_
    );
    my $user_login = get_var("USER_LOGIN") || "test";
    assert_and_click "anaconda_install_user_creation", '', $args{timeout};
    assert_screen "anaconda_install_user_creation_screen";
    # wait out animation
    wait_still_screen 2;
    type_very_safely $user_login;
    type_very_safely "\t\t\t\t";
    _type_user_password();
    wait_screen_change { send_key "tab"; };
    wait_still_screen 2;
    _type_user_password();
    # even with all our slow typing this still *sometimes* seems to
    # miss a character, so let's try again if we have a warning bar.
    # But not if we're installing with a switched layout, as those
    # will *always* result in a warning bar at this point (see below)
    if (!get_var("SWITCHED_LAYOUT") && check_screen "anaconda_warning_bar", 3) {
        wait_screen_change { send_key "shift-tab"; };
        wait_still_screen 2;
        _type_user_password();
        wait_screen_change { send_key "tab"; };
        wait_still_screen 2;
        _type_user_password();
    }
    assert_and_click "anaconda_install_user_creation_make_admin";
    assert_and_click "anaconda_spoke_done";
    # since 20170105, we will get a warning here when the password
    # contains non-ASCII characters. Assume only switched layouts
    # produce non-ASCII characters, though this isn't strictly true
    if (get_var('SWITCHED_LAYOUT') && check_screen "anaconda_warning_bar", 3) {
        wait_still_screen 1;
        assert_and_click "anaconda_spoke_done";
    }
}

sub check_desktop_clean {
    # Check we're at a 'clean' desktop. This used to be a simple
    # needle check, but Rawhide's default desktop is now one which
    # changes over time, and the GNOME top bar is now translucent
    # by default; together these changes mean it's impossible to
    # make a reliable needle, so we need something more tricksy to
    # cover that case. 'tries' is the amount of check cycles to run
    # before giving up and failing; each cycle should take ~3 secs.
    my %args = (
        tries => 10,
        @_
    );
    foreach my $i (1..$args{tries}) {
        # we still *do* the needle check, for all cases it covers
        return if (check_screen "graphical_desktop_clean", 1);
        # now do the special GNOME case
        if (get_var("DESKTOP") eq "gnome") {
            send_key "super";
            if (check_screen "overview_app_grid", 2) {
                send_key "super";
                wait_still_screen 3;
                # go back to the desktop, if we're still at the app
                # grid (can be a bit fuzzy depending on response lag)
                while (check_screen "overview_app_grid", 1) {
                    send_key "super";
                    wait_still_screen 3;
                }
                return;
            }
        }
        else {
            # to keep the timing equal
            sleep 2;
        }
    }
    die "Clean desktop not reached!";
}
