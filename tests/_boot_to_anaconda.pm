use base "anacondatest";
use strict;
use lockapi;
use testapi;
use utils;
use tapnet;
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
    $repourl = get_var("ADD_REPOSITORY_VARIATION");
    if ($repourl) {
        $params .= "inst.addrepo=addrepo," . get_full_repo($repourl) . " ";
    }
    if (get_var("ANACONDA_TEXT")) {
        $params .= "inst.text ";
        # we need this on aarch64 till #1594402 is resolved,
        # and we also can utilize this if we want to run this
        # over the serial console.
        $params .= "console=tty0 " if (get_var("ARCH") eq "aarch64");
        # when the text installation should run over the serial console,
        # we have to add some more parametres to grub. Although, the written
        # test case recommends using ttyS0, OpenQA only uses that console for
        # displaying information but does not accept key strokes. Therefore,
        # let us use a real virtio console here.
        if (get_var("SERIAL_CONSOLE")) {
            # this is icky. on ppc64 (OFW), virtio-console is hvc1 and
            # virtio-console1 is hvc2, because the 'standard' serial
            # terminal is hvc0 (the firmware does this or something).
            # On other arches, the 'standard' serial terminal is ttyS0,
            # so virtio-console becomes hvc0 and virtio-console1 is
            # hvc1. We want anaconda to wind up on the console that is
            # virtio-console1 in both cases
            if (get_var("OFW")) {
                $params .= "console=hvc2 ";
            }
            else {
                $params .= "console=hvc1 ";
            }
        }
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

    # call do_bootloader with postinstall=0, the params, and the mutex,
    # unless we're a VNC install client (no bootloader there)
    unless (get_var("VNC_CLIENT")) {
        do_bootloader(postinstall=>0, params=>$params, mutex=>$mutex, timeout=>$timeout);
    }

    # Read variables for identification tests (see further).
    my $identification = get_var('IDENTIFICATION');
    # proceed to installer
    if (get_var("KICKSTART") || get_var("VNC_SERVER")) {
        # wait for the bootloader *here* - in a test that inherits from
        # anacondatest - so that if something goes wrong during install,
        # we get anaconda logs. sleep a bit first so we don't get a
        # match for the installer bootloader if it hangs around for a
        # while after do_bootloader finishes (in PXE case it does)
        sleep 20;
        assert_screen "bootloader", 3600;
    }
    else {
        if (get_var("ANACONDA_TEXT")) {
            # select that we don't want to start VNC; we want to run in text mode
            if (get_var("SERIAL_CONSOLE")) {
                # we direct the installer to virtio-console1, and use
                # virtio-console as a root console
                select_console('virtio-console1');
                unless (wait_serial "Use text mode", timeout=>120) { die "Anaconda has not started."; }
                type_string "2\n";
                unless (wait_serial "Installation") { die "Text version of Anaconda has not started."; }
            }
            else {
                if (get_var("DISTRI") eq "rocky") {
                    # Rocky doesn't have network enabled at boot so we are not prompted
                    # for VNC...
                    # wait for text version of Anaconda main hub
                    assert_screen "anaconda_main_hub_text", 300;
                }
                else {
                    # Fedora has a use text mode menu here
                    assert_screen "anaconda_use_text_mode", 300;
                    type_string "2\n";
                    # wait for text version of Anaconda main hub
                    assert_screen "anaconda_main_hub_text", 300;
                }
            }
        }
        else {
            # on lives, we have to explicitly launch anaconda
            if (get_var('LIVE')) {
                assert_screen ["live_start_anaconda_icon", "apps_menu_button_active"], 300;
                send_key "alt-f1" if match_has_tag "apps_menu_button_active";
                # for KDE we need to double-click after kde-settings-34.6-1,
                # which is stable now.
                # FIXME: when F33 goes EOL, make the condition just "if kde"
                my $relnum = get_release_number;
                my $dclick = 0;
                $dclick = 1 if (get_var("DESKTOP") eq "kde" && $relnum > 33);
                assert_and_click("live_start_anaconda_icon", dclick=>$dclick);
                unless (check_screen "anaconda_select_install_lang", 180) {
                    # click it again - on KDE since 2019-10 or so it seems
                    # like the first attempt sometimes just doesn't work
                    assert_and_click("live_start_anaconda_icon", dclick=>$dclick, timeout=>300);
                }
            }
            my $language = get_var('LANGUAGE') || 'english';
            # wait for anaconda to appear; we click to work around
            # RHBZ #1566066 if it happens
            assert_and_click("anaconda_select_install_lang", timeout=>300);

            # Select install language
            wait_screen_change { assert_and_click "anaconda_select_install_lang_input"; };
            type_safely $language;
            # Needle filtering in main.pm ensures we will only look for the
            # appropriate language, here
            assert_and_click "anaconda_select_install_lang_filtered";
            assert_screen "anaconda_select_install_lang_selected", 10;
            # Check for Help on the Language selection pane, if HELPCHECK is
            # required
            if (get_var('HELPCHECK')) {
                check_help_on_pane("language_selection");
            }

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
