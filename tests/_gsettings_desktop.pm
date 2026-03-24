use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $distri = get_var("DISTRI");
    my $desktop = get_var("DESKTOP");
    my $user_login = get_var("USER_LOGIN", "test");
    my $user_password = get_var("USER_PASSWORD", "weakpassword");
    my $idle_delay = get_var("GNOME_DESKTOP_SESSION_IDLE_DELAY", "3600");
    my $lock_enabled = get_var("GNOME_DESKTOP_SCREENSAVER_LOCK_ENABLED", "false");

    if ($distri eq "rocky" && $desktop eq "gnome" && $user_login ne "false") {

        # switch to console
        select_console "tty3-console";

        # gsettings are for USER environment so login as USER not root
        check_screen("login_screen", 3);
        console_login(user => $user_login, password => $user_password);
        wait_still_screen 1;

        # disable gnome session idle/lock screen behavior for user that can be
        # triggered by lengthy updates
        #   script_run($cmd [, timeout => $timeout] [, output => ''] [, quiet => $quiet] [,max_interval => $max_interval]);
        type_safely "gsettings set org.gnome.desktop.session idle-delay $idle_delay\n";
        type_safely "gsettings set org.gnome.desktop.screensaver lock-enabled $lock_enabled\n";
        wait_still_screen 1;

        # logout
        type_safely "exit\n";
        check_screen("login_screen", 3);
    }
}

1;

# vim: set sw=4 et:
