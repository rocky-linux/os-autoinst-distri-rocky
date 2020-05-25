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
    $args{termstart} //= 1;
    $args{termstop} //= 1;
    my $name = $args{name};
    my $login = $args{login};
    my $password = $args{password};

    if ($args{termstart}) {
        menu_launch_type $term;
        wait_still_screen 2;
        assert_screen "apps_run_terminal";
        type_very_safely "sudo -i\n";
        type_password $syspwd;
    }
    assert_script_run "useradd -c '$name' $login";
    if ($password ne "askuser") {
        # If we want to create a user with a defined password.
        type_very_safely "passwd $login\n";
        type_password $password;
        type_password $password;
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
        assert_script_run "echo 'yes' >> /home/$login/.config/gnome-initial-setup-done";
        assert_script_run "chown -R $login.$login /home/$login/.config";
        assert_script_run "restorecon -vr /home/$login/.config";
    }
    if ($args{termstop}) {
        type_very_safely "exit\n";
        send_key 'alt-f4';
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
        # case, hit Enter to bring back the user list.
        send_key "ret";
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
        type_very_safely $password;
        send_key "ret";
    }
    type_very_safely $password;
    send_key "ret";
    check_desktop if ($args{checklogin});
    wait_still_screen 5;
}

sub check_user_logged_in {
    # Performs a check that a correct user has been locked in.
    my $user = shift;
    # In Gnome, the name of the user was accessible through menu
    # in the upper right corner, but apparently it has been removed.
    # Reading the login name from the terminal prompt seems to be
    # the most reliable thing to do.
    if ($desktop eq "gnome") {
        menu_launch_type $term;
        wait_still_screen 2;
    }
    # With KDE, the user is shown in the main menu, so let us just
    # open this and see.
    else {
        assert_and_click "system_menu_button";
    }
    assert_screen "user_confirm_$user";
    send_key "alt-f4";
    wait_still_screen 5;
}

sub logout_user {
    # Do steps to log out the user to reach the GDM screen.
    assert_and_click "system_menu_button";
    assert_and_click "power_entry";
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
        assert_and_click "power_entry";
        assert_and_click "switch_user_entry";
        wait_still_screen 5;
        # Add sleep to slow down the process a bit
        sleep 10;
    }
}

sub reboot_system {
    # Reboots the system and handles everything until the next GDM screen.
    if (check_screen "system_menu_button") {
        # Everywhere in Gnome and inside the KDE, there is a menu through which
        # we can access the operationg system switching controls.
        assert_and_click "system_menu_button";
        assert_and_click "power_entry";
        if ($desktop eq "gnome") {
            # In Gnome, some of the entries are brought together, while in KDE they are
            # split and it does not seem correct to me to assign restarting tags to
            # needles powering off the machine. So I split this for KDE and Gnome.
            # This holds true for Gnome:
            assert_and_click "power_off_entry";
            assert_and_click "restart_confirm";
        }
        else {
            # And for KDE:
            assert_and_click "reboot_entry";
            assert_and_click "log_out_confirm";
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
    # Powers-off the machine. I am not sure if this is not a useless thing to
    # do, because at the moment I do not know about a possibility to assert a
    # switched-off VM.
    assert_and_click "system_menu_button";
    assert_and_click "power_entry";
    assert_and_click "power_off_entry";
    assert_and_click "power_off_confirm";
}

sub run {
    # Do a default installation of the Fedora release you wish to test. Create two user accounts.
    my $self = shift;
    my $jackpass = "kozapanijezibaby";
    my $jimpass = "babajagakozaroza";
    our $desktop = get_var("DESKTOP");
    # Get rid of the KDE wallpaper and make background black.
    if ($desktop eq "kde") {
        solidify_wallpaper;
        # also get rid of the wallpaper on SDDM screen. This is system
        # wide so we only need do it once
        menu_launch_type $term;
        wait_still_screen 2;
        assert_screen "apps_run_terminal";
        type_very_safely "sudo -i\n";
        type_password $syspwd;
        assert_script_run "sed -i -e 's,image,solid,g' /usr/share/sddm/themes/01-breeze-fedora/theme.conf.user";
    }
    if ($desktop eq "kde") {
        # we're already at a terminal! EFFICIENCY!
        adduser(name=>"Jack Sparrow", login=>"jack", password=>$jackpass, termstart=>0, termstop=>0);
    }
    else {
        # gotta start the terminal
        adduser(name=>"Jack Sparrow", login=>"jack", password=>$jackpass, termstart=>1, termstop=>0);
    }
    if ($desktop eq "gnome") {
        # In Gnome, we can create a passwordless user that can provide his password upon
        # the first login. So we can create the second user in this way to test this feature
        # later.
        adduser(name=>"Jim Eagle", login=>"jim", password=>"askuser", termstart=>0, termstop=>1);
    }
    else {
        # In KDE, we can also create a passwordless user, but we cannot log into the system
        # later, so we will create the second user the standard way.
        adduser(name=>"Jim Eagle", login=>"jim", password=>$jimpass, termstart=>0, termstop=>1);
    }

    # Clean boot the system, and note what accounts are listed on the login screen.
    # Log out the default user "test" and reboot the system
    # before the actual testing starts. There is no need to check specifically
    # if the users are listed, because if they are not, the login tests will fail
    # later.
    logout_user();
    reboot_system();

    # Log in with the first user account.
    login_user(user=>"jack", password=>$jackpass);
    # Because some of the desktop candiness is based on semi-transparent items that change colours
    # with every background change, we want to get rid of the background and make it a solid color.
    solidify_wallpaper;
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
    # The backgrounds must be solid for both newly created users to take effect in the login session.
    solidify_wallpaper;
    check_user_logged_in("jim");
    # And this time reboot the system using the menu.
    reboot_system();

    # Try to log in with either account, intentionally entering the wrong password.
    login_user(user=>"jack", password=>"wrongpassword", checklogin=>0);
    if ($desktop eq "gnome") {
        # In GDM, a message is shown about an unsuccessful login and it can be
        # asserted, so let's do it. In SDDM, there is also a message, but it
        # is only displayed for a short moment and the assertion fails here, 
        # so we will skip the assertion. Not being able to login in with
        # a wrong password is enough here.
        assert_screen "login_wrong_password";
        send_key 'esc';
    }

    # Now, log into the system again using the correct password.
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
    check_shutdown;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
