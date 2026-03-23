use base "installedtest";
use strict;
use testapi;
use utils;
use freeipa;

sub run {
    my $self = shift;
    my $distri = get_var("DISTRI");
    my $version_major = get_version_major();
    my $desktop = get_var("DESKTOP");
    my $user_login = get_var("USER_LOGIN");

    # Expects to arrive here from freeipa_webui at a text console. When
    # run with DESKTOP = gnome we start SUT with _graphical_wait_login
    # (req'd for Rocky 10+) thus if we arrive here at a graphical log screen
    # so we need to force console mode.

    # switch to TTY3 for graphical tests, console tests already using tty3
    # NOTE: The choice of TTY3 comes from _console_wait_login test.
    if ($distri eq "rocky" && $desktop eq "gnome" && $user_login ne "false") {
        $self->root_console(tty => 3);
        assert_screen("root_console");
    }
    else {
        console_login(user => 'root');
    }
    wait_still_screen 1;

    # check whether test3 exists, i.e. whether freeipa_webui at
    # least managed to create it. if not, we may as well just
    # die now, this test cannot work.
    assert_script_run 'getent passwd test3@TEST.OPENQA.ROCKYLINUX.ORG';

    # clear browser data so we don't go back to the 'admin' login
    assert_script_run 'rm -rf /root/.mozilla';

    # clear kerberos ticket so we don't auto-auth as 'test4'
    assert_script_run 'kdestroy -A';

    # we use test3 for this test; this means it'll fail if the webUI
    # test fails before creating test3 and setting its password, but
    # changing test1's password can cause other client tests to fail
    # if they try and auth as test1 while it's changed
    start_webui("test3", "batterystaple");
    assert_and_click "freeipa_webui_actions";
    assert_and_click "freeipa_webui_reset_password_link";
    wait_still_screen 3;
    type_safely "batterystaple";

    # The next box we need to type into was moved in FreeIPA 4.8.9,
    # which is in F32+ but not F31, Rocky 8->F23, 9->F34 and 10->F40
    my $relnum = get_release_number;

    # Because Rocky relnum will always be very low the logic of this comparison
    # and action, which is originally...
    #
    # $relnum < 32 ? type_safely "\t\t" : type_safely "\t";
    #
    # ...needs to include the DISTRI unless/until we deprecate all upstream
    # funtionality in os-autoinst-distri-rocky fork.
    #
    # NOTE: When we finally drop support / testing for Rocky 8 in openQA this
    (($distri ne "rocky" && $relnum < 32) || ($distri eq "rocky" && $version_major < 9)) ? type_safely "\t\t" : type_safely "\t";
    # workaround can be removed as has been done already upstream. When ready
    # everything between "batterystaple" above and "loremipsum" below can be
    # replaced with...
    # send_key("tab");
    type_safely "loremipsum";
    wait_screen_change { send_key "tab"; };
    type_safely "loremipsum";
    assert_and_click "freeipa_webui_reset_password_button";
    wait_still_screen 2;

    # log out
    assert_and_click "freeipa_webui_user_menu";
    wait_still_screen 2;
    assert_and_click "freeipa_webui_logout";
    wait_still_screen 3;

    # close browser, back to console
    quit_firefox;

    # switch to TTY3 for graphical tests, console tests already using tty3
    # NOTE: The choice of TTY3 comes from _console_wait_login test.
    if ($distri eq "rocky" && $desktop eq "gnome" && $user_login ne "false") {
        $self->root_console(tty => 3);
        assert_screen("root_console");
    }

    # check we can kinit with changed password
    assert_script_run 'printf "loremipsum" | kinit test3';

    # change password via CLI (back to batterystaple, as that's what
    # freeipa_client test expects)
    assert_script_run 'dnf -y install freeipa-admintools';
    assert_script_run 'printf "batterystaple\nbatterystaple" | ipa user-mod test3 --password';

    # check we can kinit again
    assert_script_run 'printf "batterystaple" | kinit test3';

    # clear kerberos ticket for freeipa_client test
    assert_script_run 'kdestroy -A';

    # we just stay here - freeipa_client will pick right up
    # but clear screen to avoid false needle matches
    type_safely "clear\n";
}

sub test_flags {
    return {'ignore_failure' => 1};
}

1;
