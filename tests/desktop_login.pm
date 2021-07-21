use base "installedtest";
use strict;
use testapi;
use utils;

our $desktop = get_var("DESKTOP");
our $syspwd = get_var("USER_PASSWORD") || "weakpassword";
our $term = "gnome-terminal";
if ($desktop eq "kde") {
    $term = "konsole";
}

sub type_password {
    # Safe typing prolongs the operation terribly.
    # Let's just use type_string and wait afterwards.
    my $string = shift;
    type_string "$string\n";
    sleep 3;
}

sub adduser {
    # Add user to the system.
    my %args = @_;
    $args{termstop} //= 1;
    my $name = $args{name};
    my $login = $args{login};
    my $password = $args{password};

    assert_script_run "useradd -c '$name' $login";
    if ($password ne "askuser") {
        # If we want to create a user with a defined password.
        assert_script_run "echo '$login:$password' | chpasswd";
    }
    else {
        # If we want to create a user without a password,
        # that forces GDM to create a password upon the
        # first login.
        assert_script_run "passwd -d $login";
        assert_script_run "chage --lastday 0 $login";
    }
    assert_script_run "grep $login /etc/passwd";
    # Disable Gnome initial setup on accounts when testing
    # inside Gnome.
    if ($desktop eq "gnome") {
        assert_script_run "mkdir /home/$login/.config";
        # gnome-initial-setup-done is obsolete from F34 onwards, can be removed after F33 EOL
        assert_script_run "echo 'yes' >> /home/$login/.config/gnome-initial-setup-done";
        assert_script_run "chown -R $login.$login /home/$login/.config";
        assert_script_run "restorecon -vr /home/$login/.config";
    }
}

sub lock_screen {
    # Click on buttons to lock the screen.
    #my $desktop = get_var("DESKTOP");
    assert_and_click "system_menu_button";
    if ($desktop eq "kde") {
        assert_and_click "leave_button";
    }
    assert_and_click "lock_button";
    wait_still_screen 10;
}

sub login_user {
    # Do steps to unlock a previously locked screen. We use it to handle
    # logins as well, because it is practically the same.
    my %args = @_;
    $args{checklogin} //= 1;
    $args{method} //= "";
    my $user = $args{user};
    my $password = $args{password};
    my $method = $args{method};
    if (!check_screen "login_$user") {
        # Sometimes, especially in SDDM, we do not get the user list
        # but rather a "screensaver" screen for the DM. If this is the
        # case, hit Escape to bring back the user list.
        send_key "esc";
        wait_still_screen 5;
    }
    if ($method ne "unlock") {
        # When we do not just want to unlock the screen, we need to select a user.
        assert_and_click "login_$user";
        wait_still_screen 5;
    }
    if ($method eq "create") {
        # With users that do not have passwords, we need to make an extra round
        # of password typing.
        type_very_safely "$password\n";
    }
    type_very_safely "$password\n";
    check_desktop(timeout=>60) if ($args{checklogin});
    wait_still_screen 5;
}

sub check_user_logged_in {
    # Performs a check that a correct user has been locked in.
    my $user = shift;
    my $exitkey;
    # In Gnome, the name of the user was accessible through menu
    # in the upper right corner, but apparently it has been removed.
    # Reading the login name from the terminal prompt seems to be
    # the most reliable thing to do.
    if ($desktop eq "gnome") {
        menu_launch_type $term;
        wait_still_screen 2;
        $exitkey = "alt-f4";
    }
    # With KDE, the user is shown in the main menu, so let us just
    # open this and see.
    else {
        assert_and_click "system_menu_button";
        $exitkey = "esc";
    }
    assert_screen "user_confirm_$user";
    send_key $exitkey;
    wait_still_screen 5;
}

sub logout_user {
    # Do steps to log out the user to reach the login screen.
    assert_and_click "system_menu_button";
    assert_and_click "leave_button";
    assert_and_click "log_out_entry";
    assert_and_click "log_out_confirm";
    wait_still_screen 5;
    sleep 10;
}

sub switch_user {
    # Switch the user, i.e. leave the current user logged in and
    # log in another user simultaneously.
    send_key "ret";
    if (check_screen "locked_screen_switch_user", 5) {
        assert_and_click "locked_screen_switch_user";
    }
    elsif (check_screen "system_menu_button") {
        # The system_menu_button indicates that we are in an active
        # and unlocked session, where user switching differs
        # from a locked but active session.
        assert_and_click "system_menu_button";
        assert_and_click "leave_button";
        assert_and_click "switch_user_entry";
        wait_still_screen 5;
        # Add sleep to slow down the process a bit
        sleep 10;
    }
}

sub reboot_system {
    # Reboots the system and handles everything until the next GDM screen.
    if (check_screen "system_menu_button") {
        # In a logged in desktop, we access power options through system menu
        assert_and_click "system_menu_button";
        # In KDE since F34, reboot entry is right here, otherwise we need to
        # enter some kind of power option submenu
        assert_screen ["power_entry", "reboot_entry"];
        click_lastmatch;
        if (match_has_tag("power_entry")) {
            my $relnum = get_release_number;
            if ($desktop eq "gnome" && $relnum < 33) {
                # In GNOME before F33, some of the entries are brought together, while
                # in KDE and GNOME from F33 onwards they are split and it does not seem
                # correct to me to assign restarting tags to needles powering off the
                # machine. So I split this for KDE and GNOME < F33:
                assert_and_click "power_off_entry";
            }
            else {
                # And for KDE and GNOME >= F33:
                assert_and_click "reboot_entry";
            }
        assert_and_click "restart_confirm";
        }
    }
    # When we are outside KDE (not logged in), the only way to reboot is to click
    # the reboot icon.
    else {
        assert_and_click "reboot_icon";
    }
    boot_to_login_screen();
}

sub power_off {
    # Powers-off the machine.
    assert_and_click "system_menu_button";
    # in KDE since F34, there's no submenu to access, the button is right here
    assert_screen ["power_entry", "power_off_entry"];
    click_lastmatch;
    assert_and_click "power_off_entry" if (match_has_tag("power_entry"));
    assert_and_click "power_off_confirm";
    assert_shutdown;
}

sub run {
    # Do a default installation of the Fedora release you wish to test. Create two user accounts.
    my $self = shift;
    my $jackpass = "kozapanijezibaby";
    my $jimpass = "babajagakozaroza";
    our $desktop = get_var("DESKTOP");
    # replace the wallpaper with a black image, this should work for
    # all desktops. Takes effect after a logout / login cycle
    $self->root_console(tty=>3);
    assert_script_run "dnf -y install GraphicsMagick", 300;
    assert_script_run "gm convert -size 1024x768 xc:black /usr/share/backgrounds/black.png";
    assert_script_run 'for i in /usr/share/backgrounds/f*/default/*.png; do ln -sf /usr/share/backgrounds/black.png $i; done';
    if ($desktop eq "kde") {
        # use solid blue background for SDDM
        assert_script_run "sed -i -e 's,image,solid,g' /usr/share/sddm/themes/01-breeze-fedora/theme.conf.user";
    }
    adduser(name=>"Jack Sparrow", login=>"jack", password=>$jackpass);
    if ($desktop eq "gnome") {
        # suppress the Welcome Tour for new users in GNOME 40+
        assert_script_run 'printf "[org.gnome.shell]\nwelcome-dialog-last-shown-version=\'4294967295\'\n" > /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override';
        assert_script_run 'glib-compile-schemas /usr/share/glib-2.0/schemas';
        # In Gnome, we can create a passwordless user that can provide his password upon
        # the first login. So we can create the second user in this way to test this feature
        # later.
        adduser(name=>"Jim Eagle", login=>"jim", password=>"askuser");
    }
    else {
        # In KDE, we can also create a passwordless user, but we cannot log into the system
        # later, so we will create the second user the standard way.
        adduser(name=>"Jim Eagle", login=>"jim", password=>$jimpass);
    }

    # Clean boot the system, and note what accounts are listed on the login screen.
    # There is no need to check specifically if the users are listed, because if they
    # are not, the login tests will fail later.
    script_run "systemctl reboot", 0;
    boot_to_login_screen;

    # Log in with the first user account.
    login_user(user=>"jack", password=>$jackpass);
    check_user_logged_in("jack");
    # Log out the user.
    logout_user();

    # Log in with the second user account. The second account, Jim Eagle,
    if ($desktop eq "gnome") {
        # If we are in Gnome, we will this time assign a password on first log-in.
        login_user(user=>"jim", password=>$jimpass, method=>"create");
    }
    else {
        # If not, we are in KDE and we will log in normally.
        login_user(user=>"jim", password=>$jimpass);
    }
    check_user_logged_in("jim");
    # And this time reboot the system using the menu.
    reboot_system();

    # Try to log in with either account, intentionally entering the wrong password.
    login_user(user=>"jack", password=>"wrongpassword", checklogin=>0);
    my $relnum = get_release_number;
    if ($desktop eq "gnome" && $relnum < 34) {
        # In GDM before F34, a message is shown about an unsuccessful login
        # and it can be asserted, so let's do it. In SDDM and GDM F34+,
        # there is also a message, but it is only displayed for a short
        # moment and the assertion fails here,  so we will skip the assertion.
        # Not being able to login in with a wrong password is enough here.
        assert_screen "login_wrong_password";
        send_key 'esc';
    }
    send_key 'esc' unless (check_screen "login_jim");

    # Now, log into the system again using the correct password. This will
    # only work if we were correctly denied login with the wrong password,
    # if we were let in with the wrong password it'll fail
    login_user(user=>"jim", password=>$jimpass);
    check_user_logged_in("jim");

    # Lock the screen and unlock again.
    lock_screen();
    # Use the password to unlock the screen.
    login_user(user=>"jim", password=>$jimpass, method=>"unlock");

    # Switch user tests
    if ($desktop eq "gnome") {
        # Because KDE at the moment (20200403) is very unreliable concerning switching the users inside
        # the virtual machine, we will skip this part, until situation is better. Switching users will
        # be only tested in Gnome.

        # Start a terminal session to monitor on which sessions we are, when we start switching users.
        # This time, we will open the terminal window manually because we want to leave it open later.
        menu_launch_type "terminal";
        wait_still_screen 2;
        # Initiate switch user
        switch_user();
        # Now, we get a new login screen, so let's do the login into the new session.
        login_user(user=>"jack", password=>$jackpass);
        # Check that it is a new session, the terminal window should not be visible.
        if (check_screen "user_confirm_jim") {
            die "The session was not switched!";
        }
        else {
            check_user_logged_in("jack");
        }
        # Log out the user.
        logout_user();
        # Now, let us log into the original session, this time, the terminal window
        # should still be visible.
        login_user(user=>"jim", password=>$jimpass);
        assert_screen "user_confirm_jim";

        # We will also test another alternative - switching the user from
        # a locked screen.
        lock_screen();
        send_key "ret";
        switch_user();
        login_user(user=>"jack", password=>$jackpass);
        check_user_logged_in("jack");
    }
    # Power off the machine
    power_off();
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
