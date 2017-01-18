use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    # check both layouts are available at the desktop; here,
    # we can expect input method switching to work too
    desktop_switch_layout 'ascii';
    desktop_switch_layout 'native';
    # special testing for Japanese to ensure input method actually
    # works. If we ever test other input-method based languages we can
    # generalize this out, for now we just inline Japanese
    if (get_var("LANGUAGE") eq 'japanese') {
        # assume we can test input from whatever 'alt-f1' opens
        send_key "alt-f1";
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
        assert_screen "graphical_desktop_clean";
    }
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
