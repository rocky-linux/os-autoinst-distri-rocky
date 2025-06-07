use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $user = get_var("USER_LOGIN", "test");

    console_login();

    assert_script_run("flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo");
    assert_script_run('flatpak install -y net.sourceforge.ExtremeTuxRacer', timeout => 300);
    assert_script_run "flatpak install -y flathub org.gnome.clocks",300;
    assert_script_run("curl -O " . autoinst_url . "/data/video.ogv", timeout => 120);
    assert_script_run("mv video.ogv /home/$user/Videos/");
    script_run("chown $user:$user /home/$user/Videos/video.ogv");

    desktop_vt();
    set_update_notification_timestamp()
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:



