use base "anacondalog";
use strict;
use testapi;

sub run {
    # Wait for bootloader to appear

    assert_screen "bootloader", 30;

    # Make sure we skip media check if it's selected by default. Standard
    # 'boot installer' menu entry is always first.
    send_key "up";
    send_key "up";

    if( get_var("GRUB")){
        send_key "tab";
        type_string " ".get_var("GRUB");

    }

    if (get_var("REPOSITORY_VARIATION")){
        unless (get_var("GRUB")){
            send_key "tab";
        }
        my $fedora_version = "";
        my $repourl = "";

        $fedora_version = lc((split /_/, get_var("BUILD"))[0]);

        $repourl = get_var("REPOSITORY_VARIATION")."/".$fedora_version."/".get_var("ARCH")."/os";
        type_string " inst.repo=".$repourl;
    }

    send_key "ret";

    unless (get_var("KICKSTART"))
    {
        # on lives, we have to explicitly launch anaconda
        if (get_var('LIVE')) {
            assert_and_click "live_initial_anaconda_launcher", '', 300;
        }
        # wait for anaconda to appear
        assert_screen "anaconda_select_install_lang", 300;
        # Select install language
        assert_and_click "anaconda_select_install_lang_input";
        type_string "english";
        assert_and_click "anaconda_select_install_lang_english_filtered";
        assert_screen "anaconda_select_install_lang_english_selected", 3;
        assert_and_click "anaconda_select_install_lang_continue";

        if ( check_screen "anaconda_rawhide_accept_fate" ) {
            assert_and_click "anaconda_rawhide_accept_fate";
        }

        # Anaconda hub
        assert_screen "anaconda_main_hub", 900; #
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
