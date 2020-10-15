use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    # do this from the overview because the desktop uses the stupid
    # transparent top bar which messes with our needles
    send_key "alt-f1";
    assert_screen "overview_app_grid";
    # check both layouts are available at the desktop; here,
    # we can expect input method switching to work too
    desktop_switch_layout 'ascii';
    desktop_switch_layout 'native';
    # special testing for Japanese to ensure input method actually
    # works. If we ever test other input-method based languages we can
    # generalize this out, for now we just inline Japanese
    if (get_var("LANGUAGE") eq 'japanese') {
        # wait a bit for input switch to complete
        sleep 3;

        # assume we can test input from whatever 'alt-f1' opened
        type_safely "yama";
        assert_screen "desktop_yama_hiragana";
        send_key "spc";
        assert_screen "desktop_yama_kanji";
        send_key "spc";
        assert_screen "desktop_yama_chooser";
        send_key "esc";
        send_key "esc";
        send_key "esc";
        send_key "esc";
        check_desktop;
    }
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
