use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $relnum = get_release_number;
    if (get_var("LANGUAGE") eq 'japanese' && $relnum > 33) {
        # since g-i-s new user mode was dropped and the replacement
        # doesn't do input method selection, and anaconda never has,
        # we have to set up the input method manually:
        # https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/3749
        menu_launch_type "keyboard";
        assert_and_click "desktop_add_input_source";
        assert_and_click "desktop_input_source_japanese";
        assert_and_click "desktop_input_source_japanese_anthy";
        send_key "ret";
        wait_still_screen 3;
        send_key "alt-f4";
    }
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
