use base "anacondatest";
use strict;
use lockapi;
use testapi;
use utils;
use anaconda;

sub run {
    my $self = shift;
    if (get_var("PXEBOOT")) {
        # PXE tests have DELAYED_START set, so VM is not running yet,
        # because if we boot immediately PXE will time out waiting for
        # DHCP before the support server is ready. So we wait here for
        # support server to be ready, then go ahead and start the VM
        mutex_lock "support_ready";
        mutex_unlock "support_ready";
        resume_vm;
    }

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
        $params .= "inst.repo=" . get_full_repo($repourl) . " ";
    }
    # Construct inst.addrepo arg for ADD_REPOSITORY_VARIATION
    my $repourl = get_var("ADD_REPOSITORY_VARIATION");
    if ($repourl) {
        $params .= "inst.addrepo=addrepo," . get_full_repo($repourl) . " ";
    }
    if (get_var("ANACONDA_TEXT")) {
        $params .= "inst.text ";
        # we need this on aarch64 till #1594402 is resolved
        $params .= "console=tty0 " if (get_var("ARCH") eq "aarch64");
    }
    # inst.debug enables memory use tracking
    $params .= "debug" if get_var("MEMCHECK");
    # ternary: set $params to "" if it contains only spaces
    $params = $params =~ /^\s+$/ ? "" : $params;

    # set mutex wait if necessary
    my $mutex = get_var("INSTALL_UNLOCK");

    # we need a longer timeout for the PXE boot test
    my $timeout = 30;
    $timeout = 120 if (get_var("PXEBOOT"));

    # call do_bootloader with postinstall=0, the params, and the mutex
    do_bootloader(postinstall=>0, params=>$params, mutex=>$mutex, timeout=>$timeout);

    # Read variables for identification tests (see further).
    my $identification = get_var('IDENTIFICATION');
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
        }
        else {
            # on lives, we have to explicitly launch anaconda
            if (get_var('LIVE')) {
                _assert_and_click("live_start_anaconda_icon", timeout=>300);
            }
            my $language = get_var('LANGUAGE') || 'english';
            # wait for anaconda to appear; we click to work around
            # RHBZ #1566066 if it happens
            _assert_and_click("anaconda_select_install_lang", timeout=>300);
            # Select install language
            wait_screen_change { assert_and_click "anaconda_select_install_lang_input"; };
            type_safely $language;
            # Needle filtering in main.pm ensures we will only look for the
            # appropriate language, here
            assert_and_click "anaconda_select_install_lang_filtered";
            assert_screen "anaconda_select_install_lang_selected", 10;
            assert_and_click "anaconda_select_install_lang_continue";

            # wait 180 secs for hub or Rawhide warning dialog to appear
            # (per https://bugzilla.redhat.com/show_bug.cgi?id=1666112
            # the nag screen can take a LONG time to appear sometimes).
            # If the hub appears, return - we're done now. If Rawhide
            # warning dialog appears, accept it.
            if (check_screen ["anaconda_rawhide_accept_fate", "anaconda_main_hub"], 180) {
                if (match_has_tag("anaconda_rawhide_accept_fate")) {
                    assert_and_click "anaconda_rawhide_accept_fate";
                }
                else {
                    # this is when the hub appeared already, we're done
                    return;
                }
            }

            # If we want to test self identification, in the test suite
            # we set "identification" to "true".
            # Here, we will watch for the graphical elements in Anaconda main hub.
            my $branched = get_var('VERSION');
            if ($identification eq 'true' or $branched ne "Rawhide") {
                check_left_bar(); # See utils.pm
                check_prerelease();
                check_version();
            }
            # This is where we get to if we accepted fate above, *or*
            # didn't match anything: if the Rawhide warning didn't
            # show by now it never will, so we'll just wait for the
            # hub to show up.
            assert_screen "anaconda_main_hub", 900; #
        }
    }
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
