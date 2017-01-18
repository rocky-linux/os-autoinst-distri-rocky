use base "installedtest";
use strict;
use testapi;
use utils;
use freeipa;

sub run {
    my $self = shift;
    # we're restarting firefox (instead of using the same one from
    # realmd_join_cockpit) so Firefox's trusted CA store refreshes and
    # it trusts the web server cert
    start_webui("admin", "monkeys123");
    add_user("test3", "Three");
    add_user("test4", "Four");
    assert_screen "freeipa_webui_users_added";
    assert_and_click "freeipa_webui_policy";
    wait_still_screen 2;
    assert_screen "freeipa_webui_hbac";
    assert_and_click "freeipa_webui_add_button";
    wait_still_screen 2;
    assert_screen "freeipa_webui_add_policy";
    type_safely "allow-test3";
    type_safely "\t\t\t";
    send_key "ret";
    assert_and_click "freeipa_webui_policy_add_user";
    wait_still_screen 2;
    # filter users
    type_safely "test3\n";
    # go to the correct checkbox (assert_and_click is tricky as
    # we can't make sure we click the right checkbox), check it,
    # select right arrow, click it - tab tab tab, space, tab, enter
    type_safely "\t\t\t \t\n";
    assert_and_click "freeipa_webui_add_button";
    wait_still_screen 2;
    send_key "pgdn";
    wait_still_screen 1;
    assert_and_click "freeipa_webui_policy_any_host";
    assert_and_click "freeipa_webui_policy_any_service";
    wait_still_screen 1;
    send_key "pgup";
    wait_still_screen 1;
    assert_and_click "freeipa_webui_policy_save";
    # quit browser to return to console
    send_key "ctrl-q";
    # we don't get back to a prompt instantly and keystrokes while X
    # is still shutting down are swallowed, so wait_still_screen before
    # finishing (and handing off to freeipa_client_postinstall)
    wait_still_screen 5;
    # set permanent passwords for both accounts
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test3@DOMAIN.LOCAL';
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test4@DOMAIN.LOCAL';
    # switch to tty4 (boy, the tty jugglin')
    send_key "ctrl-alt-f4";
    # try and login as test3, should work
    console_login(user=>'test3@DOMAIN.LOCAL', password=>'batterystaple');
    type_string "exit\n";
    # try and login as test4, should fail. we cannot use console_login
    # as it takes 10 seconds to complete when login fails, and
    # "permission denied" message doesn't last that long
    sleep 2;
    assert_screen "text_console_login";
    type_string "test4\@DOMAIN.LOCAL\n";
    assert_screen "console_password_required";
    type_string "batterystaple\n";
    assert_screen "login_permission_denied";
    # back to tty1
    send_key "ctrl-alt-f1";
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { milestone => 1 };
}

1;
