use base "installedtest";
use strict;
use testapi;
use utils;

# we are very paranoid with waits and typing speed in this test
# because the system can be very busy; it's effectively first boot of
# a freshly installed system and we're running Firefox for the first
# time, which causes an awful lot of system load, and there's lots of
# screen change potentially going on. This makes the test quite slow,
# but it's best to be safe. If you're working on the test you might
# want to tweak the waits down a bit and use type_safely instead of
# type_very_safely for your test runs, just to save your time.

sub run {
    my $self = shift;
    assert_screen 'graphical_desktop_clean';
    send_key 'alt-f1';
    # wait out animations
    wait_still_screen 2;
    assert_and_click 'browser_launcher';
    assert_screen 'browser';
    wait_idle 5;
    # open a new tab so we don't race with the default page load
    # (also focuses the location bar for us)
    send_key 'ctrl-t';
    wait_still_screen 2;
    wait_idle 3;
    # check FAS, typing slowly to avoid errors
    type_very_safely "https://admin.fedoraproject.org/accounts/\n";
    assert_screen "browser_fas_home";
    send_key 'ctrl-t';
    wait_still_screen 2;
    wait_idle 2;
    type_very_safely "https://kernel.org\n";
    assert_and_click "browser_kernelorg_patch";
    assert_and_click "browser_download_save";
    send_key 'ret';
    # browsers do...something...when the download completes, and we
    # expect there's a single click to make it go away and return
    # browser to a state where ctrl-t will work
    assert_and_click "browser_download_complete";
    # we'll check it actually downloaded later
    # add-on test: at present all desktops we test (KDE, GNOME) are
    # using Firefox by default so we do this unconditionally, but we
    # may need to conditionalize it if we ever test desktops whose
    # default browser doesn't support add-ons or uses different ones
    send_key 'ctrl-t';
    wait_still_screen 2;
    wait_idle 2;
    type_very_safely "https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/\n";
    assert_and_click "firefox_addon_add";
    assert_and_click "firefox_addon_install";
    assert_and_click "firefox_addon_success";
    # go to a console and check download worked
    $self->root_console(tty=>3);
    my $user = get_var("USER_LOGIN", "test");
    assert_script_run "test -e /home/$user/Downloads/patch-*.xz";
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
