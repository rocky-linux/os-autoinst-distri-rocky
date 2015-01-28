use base "basetest";
use strict;
use testapi;

sub run {
    # Wait for bootloader to appear

    assert_screen "bootloader", 30;

    if ( get_var("FLAVOR") eq "server")
    {
        # Skip the media check on DVD
        send_key "up";
    }

    if ( get_var("KICKSTART") )
    {
        if ( get_var("BOOT_KICKSTART_HTTP") )
        {
            send_key "tab";
            type_string " inst.ks=http://jskladan.fedorapeople.org/kickstarts/root-user-crypted-net.ks";
        }

        send_key "ret";
    }
    else
    {
        if ( get_var("BOOT_UPDATES_IMG_URL") )
        {
            send_key "tab";
            type_string " inst.updates=https://fedorapeople.org/groups/qa/updates/updates-unipony.img";
        }

        send_key "ret";
        # Select install language
        assert_screen "anaconda_select_install_lang", 300;
        type_string "english";
        assert_and_click "anaconda_select_install_lang_english_filtered";
        assert_screen "anaconda_select_install_lang_english_selected", 3;
        assert_and_click "anaconda_select_install_lang_continue";

        # Anaconda hub
        assert_screen "anaconda_main_hub", 300; #
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
