use base "anacondatest";
use strict;
use testapi;
use main_common;

sub run {
    my $self = shift;
    # construct the kernel params. the trick here is to wind up with
    # spaced params if GRUB or GRUBADD is set, and just spaces if not,
    # then check if we got all spaces. We wind up with a harmless
    # extra space if GRUBADD is set but GRUB is not.
    my $params = "";
    $params .= get_var("GRUB", "") . " ";
    $params .= get_var("GRUBADD", "") . " ";
    # Construct inst.repo arg for REPOSITORY_VARIATION
    my $repourl = get_var("REPOSITORY_VARIATION");
    if ($repourl) {
        $params .= "inst.repo=" . $self->get_full_repo($repourl) . " ";
    }
    $params .= "inst.text " if get_var("ANACONDA_TEXT");
    # inst.debug enables memory use tracking
    $params .= "debug" if get_var("MEMCHECK");
    # ternary: set $params to "" if it contains only spaces
    $params = $params =~ /^\s+$/ ? "" : $params;

    # set mutex wait if necessary
    my $mutex = get_var("INSTALL_UNLOCK");

    # call do_bootloader with postinstall=0, the params, and the mutex
    $self->do_bootloader(postinstall=>0, params=>$params, mutex=>$mutex);

    # proceed to installer
    if (get_var("KICKSTART")) {
        # wait for the bootloader *here* - in a test that inherits from
        # anacondatest - so that if something goes wrong during install,
        # we get anaconda logs
        assert_screen "bootloader", 1800;
    }
    else {
        if (get_var("ANACONDA_TEXT")) {
            # select that we don't want to start VNC; we want to run in text mode
            assert_screen "anaconda_use_text_mode", 300;
            type_string "2\n";
            # wait for text version of Anaconda main hub
            assert_screen "anaconda_main_hub_text", 300;
        } else {
            # on lives, we have to explicitly launch anaconda
            if (get_var('LIVE')) {
                assert_and_click "live_start_anaconda_icon", '', 300;
            }
            my $language = get_var('LANGUAGE') || 'english';
            # wait for anaconda to appear
            assert_screen "anaconda_select_install_lang", 300;
            # Select install language
            wait_screen_change { assert_and_click "anaconda_select_install_lang_input"; };
            type_safely $language;
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
