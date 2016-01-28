use base "anacondatest";
use strict;
use testapi;

# get_kernel_line switches to menu edit screen and sets the cursor to the end of kernel line
sub get_kernel_line {
    if( get_var("UEFI")){
        send_key "e";
        send_key "down";
        send_key "down";
        send_key "end";
    } else {
        send_key "tab";
    }
}

sub run {
    # Wait for bootloader to appear
    if( get_var("UEFI")){
        assert_screen "bootloader_uefi", 30;
    } else {
        assert_screen "bootloader", 30;
    }

    # Make sure we skip media check if it's selected by default. Standard
    # 'boot installer' menu entry is always first.
    send_key "up";
    send_key "up";

    # if variable GRUB is set, add its value into kernel line in grub
    if( get_var("GRUB")){
        get_kernel_line;
        type_string " ".get_var("GRUB");

    }

    # if variable REPOSITORY_VARIATION is set, construct inst.repo url and add it to kernel line
    if (get_var("REPOSITORY_VARIATION")){
        unless (get_var("GRUB")){
            get_kernel_line;
        }
        my $repourl = "";

        # REPOSITORY_VARIATION should be set to repository URL without version and architecture
        # appended (it will be appended automatically)
        $repourl = get_var("REPOSITORY_VARIATION")."/".$self->get_release."/".get_var("ARCH")."/os";
        type_string " inst.repo=".$repourl;
    }

    # now we are on the correct "boot" menu item
    # hit Ctrl+x for the case when the uefi kernel line was edited
    send_key "ctrl-x";
    # Return starts boot in all other cases
    send_key "ret";

    unless (get_var("KICKSTART"))
    {
        # on lives, we have to explicitly launch anaconda
        if (get_var('LIVE')) {
            assert_and_click "live_start_anaconda_icon", '', 300;
        }
        my $language = get_var('LANGUAGE') || 'english';
        # wait for anaconda to appear
        assert_screen "anaconda_select_install_lang", 300;
        # Select install language
        assert_and_click "anaconda_select_install_lang_input";
        type_string "${language}";
        # Needle filtering in main.pm ensures we will only look for the
        # appropriate language, here
        assert_and_click "anaconda_select_install_lang_filtered";
        assert_screen "anaconda_select_install_lang_selected", 3;
        assert_and_click "anaconda_select_install_lang_continue";

        if ( check_screen "anaconda_rawhide_accept_fate" ) {
            assert_and_click "anaconda_rawhide_accept_fate";
        }

        # wait for Anaconda hub to appear
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
