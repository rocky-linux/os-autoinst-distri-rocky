use base "installedtest";
use strict;
use testapi;
use utils;

# This test tests if Terminal starts and uses it to change desktop settings for all the following tests.
# Therefore, if you want to use all the tests from the APPS family, this should be the very first to do.

sub run {
    my $self = shift;
    # open the application, let use the method that does not require any needles, 
    # because this way, the terminal will always start even if some needles
    # might fail because of changing background in various releases.
    send_key 'alt-f1';
    wait_still_screen 2;
    type_very_safely 'terminal';
    send_key 'ret';  
    wait_still_screen 5;

    # When the application opens, run command in it to set the background to black
    type_very_safely "gsettings set org.gnome.desktop.background picture-uri ''";
    send_key 'ret';
    wait_still_screen 2;
    type_very_safely "gsettings set org.gnome.desktop.background primary-color '#000000'";
    send_key 'ret';
    wait_still_screen 2;
    quit_with_shortcut();
    # check that is has changed color
    assert_screen 'apps_settings_screen_black';
}

# If this test fails, the others will probably start failing too, 
# so there is no need to continue.
# Also, when subsequent tests fail, the suite will revert to this state for further testing.
sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;

# vim: set sw=4 et:
