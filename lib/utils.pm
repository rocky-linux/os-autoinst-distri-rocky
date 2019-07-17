package utils;

use strict;

use base 'Exporter';
use Exporter;

use lockapi;
use testapi;
our @EXPORT = qw/run_with_error_check type_safely type_very_safely desktop_vt boot_to_login_screen console_login console_switch_layout desktop_switch_layout console_loadkeys_us do_bootloader boot_decrypt check_release menu_launch_type start_cockpit repo_setup gnome_initial_setup anaconda_create_user check_desktop_clean download_modularity_tests quit_firefox advisory_get_installed_packages advisory_check_nonmatching_packages start_with_launcher quit_with_shortcut disable_firefox_studies select_rescue_mode copy_devcdrom_as_isofile bypass_1691487 get_release_number _assert_and_click click_unwanted_notifications/;

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
    # similarity level 45 as there will commonly be a flashing
    # cursor and the default level (47) is slightly too tight
    wait_still_screen(stilltime=>5, similarity_level=>45);
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
        # default is 10 seconds, set below, 0 means 'default'
        timeout => 0,
        @_);
    $args{timeout} ||= 10;

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

    assert_screen [$good, 'text_console_login'], $args{timeout};
    # if we're already logged in, all is good
    if (match_has_tag $good) {
        _console_login_finish();
        return;
    }
    # otherwise, we saw the login prompt, type the username
    type_string("$args{user}\n");
    assert_screen [$good, 'console_password_required'], 30;
    # on a live image, just the user name will be enough
    if (match_has_tag $good) {
        _console_login_finish();
        return;
    }
    # otherwise, type the password
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
    # make sure we reached the console
    unless (check_screen($good, 30)) {
        # as of 2018-10 we have a bug in sssd which makes this take
        # unusually long in the FreeIPA tests, let's allow longer,
        # with a soft fail - RHBZ #1644919
        record_soft_failure "Console login is taking a long time - #1644919?";
        my $timeout = 30;
        # even an extra 30 secs isn't long enough on aarch64...
        $timeout = 90 if (get_var("ARCH") eq "aarch64");
        assert_screen($good, $timeout);
    }
    _console_login_finish();
}

# load US layout (from a root console)
sub console_loadkeys_us {
    if (get_var('LANGUAGE') eq 'french') {
        script_run "loqdkeys us", 0;
        # might take a few secs
        sleep 3;
    }
    elsif (get_var('LANGUAGE') eq 'japanese') {
        script_run "loadkeys us", 0;
        sleep 3;
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
    # we use the firmware-type specific tags because we want to be
    # sure we actually did a UEFI boot
    my $boottag = "bootloader_bios";
    $boottag = "bootloader_uefi" if ($args{uefi});
    assert_screen $boottag, $args{timeout};
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
            # we need to get to the 'linux' line here, and grub does
            # not have any easy way to do that. Depending on the arch
            # and the Fedora release, we may have to press 'down' 2
            # times, or 13, or 12, or some other goddamn number. That
            # got painful to keep track of, so let's go bottom-up:
            # press 'down' 50 times to make sure we're at the bottom,
            # then 'up' twice to reach the 'linux' line. This seems to
            # work in every permutation I can think of to test.
            for (1 .. 50) {
                send_key 'down';
            }
            sleep 1;
            send_key 'up';
            sleep 1;
            send_key 'up';
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

sub boot_decrypt {
    # decrypt storage during boot; arg is timeout (in seconds)
    my $timeout = shift || 60;
    assert_screen "boot_enter_passphrase", $timeout;
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
    my $check_command = "grep SUPPORT_PRODUCT_VERSION /etc/os-release";
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

sub disable_firefox_studies {
    # create a config file that disables Firefox's dumb 'shield
    # studies' so they don't break tests:
    # https://bugzilla.mozilla.org/show_bug.cgi?id=1529626
    assert_script_run 'mkdir -p $(rpm --eval %_libdir)/firefox/distribution';
    assert_script_run 'printf \'{"policies": {"DisableFirefoxStudies": true}}\' > $(rpm --eval %_libdir)/firefox/distribution/policies.json';
}

sub start_cockpit {
    # Starting from a console, get to a browser with Cockpit (running
    # on localhost) shown. If $login is truth-y, also log in. Assumes
    # X and Firefox are installed.
    my $login = shift || 0;
    # https://bugzilla.redhat.com/show_bug.cgi?id=1439429
    assert_script_run "sed -i -e 's,enable_xauth=1,enable_xauth=0,g' /usr/bin/startx";
    disable_firefox_studies;
    # run firefox directly in X as root. never do this, kids!
    type_string "startx /usr/bin/firefox -width 1024 -height 768 http://localhost:9090\n";
    assert_screen "cockpit_login", 30;
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
    script_run "sed -i -e 's,^metalink,#metalink,g' -e 's,^mirrorlist,#mirrorlist,g' -e 's,^#baseurl.*basearch,baseurl=${location}/Everything/\$basearch,g' -e 's,^#baseurl.*source,baseurl=${location}/Everything/source,g' /etc/yum.repos.d/{fedora,fedora-rawhide}.repo", 0;
    script_run "sed -i -e 's,^metalink,#metalink,g' -e 's,^mirrorlist,#mirrorlist,g' -e 's,^#baseurl.*basearch,baseurl=${location}/Modular/\$basearch,g' -e 's,^#baseurl.*source,baseurl=${location}/Modular/source,g' /etc/yum.repos.d/{fedora-modular,fedora-rawhide-modular}.repo", 0;

    # this can be used for debugging if something is going wrong
#    unless (script_run 'pushd /etc/yum.repos.d && tar czvf yumreposd.tar.gz * && popd') {
#        upload_logs "/etc/yum.repos.d/yumreposd.tar.gz";
#    }
}

sub _repo_setup_updates {
    # Appropriate repo setup steps for testing a Bodhi update
    # Check if we already ran, bail if so
    return unless script_run "test -f /etc/yum.repos.d/advisory.repo";
    # Use mirrorlist not metalink so we don't hit the timing issue where
    # the infra repo is updated but mirrormanager metadata checksums
    # have not been updated, and the infra repo is rejected as its
    # metadata checksum isn't known to MM
    assert_script_run "sed -i -e 's,metalink,mirrorlist,g' /etc/yum.repos.d/fedora*.repo";
    if (get_var("DEVELOPMENT")) {
        # Disable updates-testing so other bad updates don't break us
        # this will do nothing on upgrade tests as we're on a stable
        # release at this point, but it won't *hurt* anything, so no
        # need to except that case really
        assert_script_run "dnf config-manager --set-disabled updates-testing";
        # same for Modular, if appropriate
        unless (script_run 'test -f /etc/yum.repos.d/fedora-updates-modular.repo') {
            assert_script_run "dnf config-manager --set-disabled updates-testing-modular";
        }
    }

    # Set up an additional repo containing the update or task packages. We do
    # this rather than simply running a one-time update because it may be the
    # case that a package from the update isn't installed *now* but will be
    # installed by one of the tests; by setting up a repo containing the
    # update and enabling it here, we ensure all later 'dnf install' calls
    # will get the packages from the update.
    assert_script_run "mkdir -p /opt/update_repo";
    # if NUMDISKS is above 1, assume we want to put the update repo on
    # the other disk (to avoid huge updates exhausting space on the main
    # disk)
    if (get_var("NUMDISKS") > 1) {
        # I think the disk will always be vdb. This creates a single large
        # partition.
        assert_script_run "echo 'type=83' | sfdisk /dev/vdb";
        assert_script_run "mkfs.ext4 /dev/vdb1";
        assert_script_run "echo '/dev/vdb1 /opt/update_repo ext4 defaults 1 2' >> /etc/fstab";
        assert_script_run "mount /opt/update_repo";
    }
    assert_script_run "cd /opt/update_repo";
    assert_script_run "dnf -y install bodhi-client git createrepo koji", 300;

    # download the packages
    if (get_var("ADVISORY")) {
        # regular update case
        assert_script_run "bodhi updates download --updateid " . get_var("ADVISORY"), 600;
    }
    else {
        # Koji task case (KOJITASK will be set)
        assert_script_run "koji download-task --arch=" . get_var("ARCH") . " --arch=noarch " . get_var("KOJITASK"), 600;
    }
    # for upgrade tests, we want to do the 'development' changes *after* we
    # set up the update repo. We don't do the f28 fixups as we don't have
    # f28 fedora-repos.

    # this can be used for debugging if something is going wrong
#    unless (script_run 'pushd /etc/yum.repos.d && tar czvf yumreposd.tar.gz * && popd') {
#        upload_logs "/etc/yum.repos.d/yumreposd.tar.gz";
#    }

    # log the exact packages in the update at test time, with their
    # source packages and epochs
    assert_script_run 'rpm -qp *.rpm --qf "%{SOURCERPM} %{EPOCH} %{NAME}-%{VERSION}-%{RELEASE}\n" | sort -u > /var/log/updatepkgs.txt';
    upload_logs "/var/log/updatepkgs.txt";
    # also log just the binary package names: this is so we can check
    # later whether any package from the update *should* have been
    # installed, but was not
    assert_script_run 'rpm -qp *.rpm --qf "%{NAME} " > /var/log/updatepkgnames.txt';
    upload_logs "/var/log/updatepkgnames.txt";
    # create the repo metadata
    assert_script_run "createrepo .";
    # write a repo config file, unless this is the support_server test
    # and it is running on a different release than the update is for
    # (in this case we need the repo to exist but do not want to use
    # it on the actual support_server system)
    unless (get_var("TEST") eq "support_server" && get_var("VERSION") ne get_var("CURRREL")) {
        assert_script_run 'printf "[advisory]\nname=Advisory repo\nbaseurl=file:///opt/update_repo\nenabled=1\nmetadata_expire=3600\ngpgcheck=0" > /etc/yum.repos.d/advisory.repo';
        # run an update now (except for upgrade tests)
        script_run "dnf -y update", 900 unless (get_var("UPGRADE"));
    }
    # mark via a variable that we've set up the update/task repo and done
    # all the logging stuff above
    set_var('_ADVISORY_REPO_DONE', '1');
}

sub repo_setup {
    # Run the appropriate sub-function for the job
    get_var("ADVISORY_OR_TASK") ? _repo_setup_updates : _repo_setup_compose;
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
        if (check_screen "getting_started", 30) {
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
    _assert_and_click("anaconda_install_user_creation", timeout=>$args{timeout});
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

sub download_modularity_tests {
# Download the modularity test script, place in the system and then
# modify the access rights to make it executable.
    my ($whitelist) = @_;
    assert_script_run 'curl -o /root/test.py https://pagure.io/fedora-qa/modularity_testing_scripts/raw/master/f/modular_functions.py';
    if ($whitelist eq 'whitelist') {
	assert_script_run 'curl -o /root/whitelist https://pagure.io/fedora-qa/modularity_testing_scripts/raw/master/f/whitelist';
    }
    assert_script_run 'chmod 755 /root/test.py';
}

sub quit_firefox {
# Quit Firefox, handling the 'close multiple tabs' warning screen if
# it shows up
    send_key "ctrl-q";
    # expect to get to either the tabs warning or a console
    if (check_screen ["user_console", "root_console", "firefox_close_tabs"], 30) {
        # if we hit the tabs warning, click it
        assert_and_click "firefox_close_tabs" if (match_has_tag "firefox_close_tabs");
    }
    # FIXME workaround for RHBZ #1663050 - with systemd 240, at this
    # point the tty quits and we wind up back at the login prompt
    wait_still_screen 5;
    # on all paths where we hit this sub, we want to be logged in as
    # root, so let's just run through console_login again. This is
    # fine for older releases which don't have the bug, console_login
    # will just notice we're already logged in as root and return.
    console_login(user=>'root');
}

sub start_with_launcher {
# Get the name of the needle with a launcher, find the launcher in the menu
# and click on it to start the application. This function works for the
# Gnome desktop.

    # $launcher holds the launcher needle, but some of the apps are hidden in a submenu
    # so this must be handled first to find the launcher needle.
 
    my ($launcher,$submenu,$group) = @_;
    $submenu //= '';
    $group //= '';
    my $desktop = get_var('DESKTOP');
    
    my $item_to_check = $submenu || $launcher;
    # The following varies for different desktops.
    if ($desktop eq 'gnome') {
        # Start the Activities page
        send_key 'alt-f1';
        wait_still_screen 5;

        # Click on the menu icon to come into the menus
        assert_and_click 'overview_app_grid';
        wait_still_screen 5;

        # Find the application launcher in the current menu page. 
        # If it cannot be found there, hit PageDown to go to another page.

        send_key_until_needlematch($item_to_check, 'pgdn', 5, 3);

        # If there was a submenu, click on that first.
        if ($submenu) {
            assert_and_click $submenu;
            wait_still_screen 5;
        }
        # Click on the launcher
        assert_and_click $launcher;
        wait_still_screen 5;
    }
    elsif ($desktop eq 'kde'){
        # Click on the KDE launcher icon
        assert_and_click 'kde_menu_launcher';
        wait_still_screen 2;
        
        # Select the appropriate submenu 
        assert_and_click $submenu;
        wait_still_screen 2;

        # Select the appropriate menu subgroup where real launchers
        # are placed, but only if requested
        if ($group) {
	    send_key_until_needlematch($group, 'down', 20, 3);
	    send_key 'ret';
	    #assert_and_click $group;
            wait_still_screen 2;
        }

        # Find and click on the menu item to start the application
        send_key_until_needlematch($launcher, 'down', 40, 3);
        send_key 'ret';
        wait_still_screen 5;
    } 
}


sub quit_with_shortcut {
# Quit the application using the Alt-F4 keyboard shortcut
    send_key 'alt-f4';
    wait_still_screen 5;
    assert_screen 'workspace';

}

sub advisory_get_installed_packages {
    # For update tests (this only works if we've been through
    # _repo_setup_updates), figure out which packages from the update
    # are currently installed. This is here so we can do it both in
    # _advisory_post and post_fail_hook.
    return unless (get_var("_ADVISORY_REPO_DONE"));
    assert_script_run 'rpm -qa --qf "%{SOURCERPM} %{EPOCH} %{NAME}-%{VERSION}-%{RELEASE}\n" | sort -u > /tmp/allpkgs.txt';
    # this finds lines which appear in both files
    # http://www.unix.com/unix-for-dummies-questions-and-answers/34549-find-matching-lines-between-2-files.html
    if (script_run 'comm -12 /tmp/allpkgs.txt /var/log/updatepkgs.txt > /var/log/testedpkgs.txt') {
        # occasionally, for some reason, it's unhappy about sorting;
        # we shouldn't fail the test in this case, just upload the
        # files so we can see why...
        upload_logs "/tmp/allpkgs.txt", failok=>1;
        upload_logs "/var/log/updatepkgs.txt", failok=>1;
    }
    # we'll try and upload the output even if comm 'failed', as it
    # does in fact still write it in some cases
    upload_logs "/var/log/testedpkgs.txt", failok=>1;
}

sub advisory_check_nonmatching_packages {
    # For update tests (this only works if we've been through
    # _repo_setup_updates), figure out if we have a different version
    # of any package from the update installed - this indicates a
    # problem, it likely means a dep issue meant dnf installed an
    # older version from the frozen release repo
    my %args = (
        fatal => 1,
        @_
    );
    return unless (get_var("_ADVISORY_REPO_DONE"));
    # if this fails in advisory_post, we don't want to do it *again*
    # unnecessarily in post_fail_hook
    return if (get_var("_ACNMP_DONE"));
    script_run 'touch /tmp/installedupdatepkgs.txt';
    # this creates /tmp/installedupdatepkgs.txt as a sorted list of installed
    # packages with the same name as packages from the update, in the same form
    # as /var/log/updatepkgs.txt. The 'tail -1' tries to handle the problem of
    # installonly packages like the kernel, where we wind up with *multiple*
    # versions installed after the update; I'm hoping the last line of output
    # for any given package is the most recent version, i.e. the one in the
    # update.
    script_run 'for pkg in $(cat /var/log/updatepkgnames.txt); do rpm -q $pkg && rpm -q $pkg --qf "%{SOURCERPM} %{EPOCH} %{NAME}-%{VERSION}-%{RELEASE}\n" | tail -1 >> /tmp/installedupdatepkgs.txt; done';
    script_run 'sort -u -o /tmp/installedupdatepkgs.txt /tmp/installedupdatepkgs.txt';
    # if any line appears in installedupdatepkgs.txt but not updatepkgs.txt,
    # we have a problem.
    if (script_run 'comm -23 /tmp/installedupdatepkgs.txt /var/log/updatepkgs.txt > /var/log/installednotupdatedpkgs.txt') {
        # occasionally, for some reason, it's unhappy about sorting;
        # we shouldn't fail the test in this case, just upload the
        # files so we can see why...
        upload_logs "/tmp/installedupdatepkgs.txt", failok=>1;
        upload_logs "/var/log/updatepkgs.txt", failok=>1;
    }
    # this exits 1 if the file is zero-length, 0 if it's longer
    # if it's 0, that's *BAD*: we want to upload the file and fail
    unless (script_run 'test -s /var/log/installednotupdatedpkgs.txt') {
        upload_logs "/var/log/installednotupdatedpkgs.txt", failok=>1;
        upload_logs "/var/log/updatepkgs.txt", failok=>1;
        my $message = "Package(s) from update not installed when it should have been! See installednotupdatedpkgs.txt";
        if ($args{fatal}) {
            set_var("_ACNMP_DONE", "1");
            die $message;
        }
        else {
            # if we're already in post_fail_hook, we don't want to die again
            record_info $message;
        }
    }
}

sub select_rescue_mode {
    # handle bootloader screen
    assert_screen "bootloader", 30;
    if (get_var('OFW')) {
        # select "rescue system" directly
        send_key "down";
        send_key "down";
        send_key "ret";
    }
    else {
        # select troubleshooting
        send_key "down";
        send_key "ret";
        # select "rescue system"
        if (get_var('UEFI')) {
            send_key "down";
            # we need this on aarch64 till #1661288 is resolved
            if (get_var('ARCH') eq 'aarch64') {
                send_key "e";
                # duped with do_bootloader, sadly...
                for (1 .. 50) {
                    send_key 'down';
                }
                sleep 1;
                send_key 'up';
                sleep 1;
                send_key 'up';
                send_key "end";
                type_safely " console=tty0";
                send_key "ctrl-x";
            }
            else {
                send_key "ret";
            }
        }
        else {
            type_string "r\n";
        }
    }

    assert_screen "rescue_select", 120; # it takes time to start anaconda
}

sub copy_devcdrom_as_isofile {
    # copy /dev/cdrom as iso file and verify checksum is same
    # as cdrom previously retrieved from ISO_URL
    my $isoname = shift;
    assert_script_run "dd if=/dev/cdrom of=$isoname", 360;
    # verify iso checksum
    my $cdurl = get_var('ISO_URL');
    my $cmd = <<EOF;
urld="$cdurl"; urld=\${urld%/*}; chkf=\$(curl -fs \$urld/ |grep CHECKSUM | sed -E 's/.*href=.//; s/\".*//') && curl -f \$urld/\$chkf -o /tmp/x
chkref=\$(grep -E 'SHA256.*dvd' /tmp/x | sed -e 's/.*= //') && echo "\$chkref $isoname" >/tmp/x
sha256sum -c /tmp/x
EOF
    assert_script_run($_) foreach (split /\n/, $cmd);
}

sub bypass_1691487 {
    if (script_run 'echo "expected command supposed to be typed without error."') {
        record_soft_failure 'brc#1691487 bypass';
        script_run 'echo "trial bypass dup chars brc#1691487"';
    }
}

sub get_release_number {
    # return the release number; so usually VERSION, but for Rawhide,
    # we return RAWREL. This allows us to avoid constantly doing stuff
    # like `if ($version eq "Rawhide" || $version > 30)`.
    my $version = get_var("VERSION");
    my $rawrel = get_var("RAWREL", "Rawhide");
    return $rawrel if ($version eq "Rawhide");
    return $version
}

sub _assert_and_click {
    # this is a wrapper around assert_and_click which handles this:
    # https://github.com/os-autoinst/os-autoinst/pull/1075/files
    # it changed the signature without any backward compatibility, so
    # earlier os-autoinsts require an *array* of args, but later ones
    # require a *hash* of args. This works with both.
    my $version = $OpenQA::Isotovideo::Interface::version;
    my ($mustmatch, %args) = @_;
    if ($version > 13) {
        return assert_and_click($mustmatch, %args);
    }
    else {
        $args{timeout}   //= $bmwqemu::default_timeout;
        $args{button}    //= 'left';
        $args{dclick}    //= 0;
        $args{mousehide} //= 0;
        return assert_and_click($mustmatch, $args{button}, $args{timeout}, 0, $args{dclick});
    }
}

sub click_unwanted_notifications {
    # there are a few KDE tests where at some point we want to click
    # on all visible 'update available' notifications (there can be
    # more than one, thanks to
    # https://bugzilla.redhat.com/show_bug.cgi?id=1730482 ) and the
    # buggy 'akonadi_migration_agent' notification if it's showing -
    # https://bugzilla.redhat.com/show_bug.cgi?id=1716005
    # Returns an array indicating which notifications it closed
    wait_still_screen 5;
    my $count = 10;
    my @closed;
    while ($count > 0 && check_screen "desktop_update_notification_popup", 5) {
        $count -= 1;
        push (@closed, 'update');
        assert_and_click "desktop_update_notification_popup";
    }
    if (check_screen "akonadi_migration_agent", 5) {
        assert_and_click "akonadi_migration_agent";
        push (@closed, 'akonadi');
    }
    return @closed;
}
