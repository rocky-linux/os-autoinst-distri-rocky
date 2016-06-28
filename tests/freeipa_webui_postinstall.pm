use base "installedtest";
use strict;
use testapi;

sub add_user {
    my ($user, $surname) = @_;
    wait_still_screen 1;
    assert_and_click "freeipa_webui_add_button";
    assert_screen "freeipa_webui_add_user";
    wait_still_screen 1;
    type_string $user;
    wait_still_screen 1;
    send_key "tab";
    # we don't need to be too careful here as the names don't matter
    type_string "Test";
    send_key "tab";
    type_string $surname;
    send_key "tab";
    send_key "tab";
    send_key "tab";
    send_key "tab";
    type_string "correcthorse";
    wait_still_screen 1;
    send_key "tab";
    wait_still_screen 1;
    type_string "correcthorse\n";
}

sub run {
    my $self=shift;
    # we're restarting firefox (instead of using the same one from
    # freeipa_client_postinstall) so Firefox's trusted CA store
    # refreshes and it trusts the web server cert
    type_string "startx /usr/bin/firefox\n";
    assert_screen "firefox";
    # new tab
    send_key "ctrl-t";
    wait_still_screen 2;
    type_string "https://ipa001.domain.local";
    # firefox's stupid 'smart' url bar is a pain. wait for things to settle.
    wait_still_screen 3;
    send_key "ret";
    assert_screen "freeipa_webui_login";
    type_string "admin";
    wait_still_screen 1;
    send_key "tab";
    wait_still_screen 1;
    type_string "monkeys123";
    wait_still_screen 1;
    send_key "ret";
    assert_screen "freeipa_webui_users";
    add_user("test3", "Three");
    add_user("test4", "Four");
    assert_screen "freeipa_webui_users_added";
    assert_and_click "freeipa_webui_policy";
    assert_and_click "freeipa_webui_add_button";
    assert_screen "freeipa_webui_add_policy";
    type_string "allow-test3";
    wait_still_screen 1;
    send_key "tab";
    send_key "tab";
    send_key "tab";
    wait_still_screen 1;
    send_key "ret";
    assert_and_click "freeipa_webui_policy_add_user";
    # filter users
    type_string "test3\n";
    # go to the correct checkbox (assert_and_click is tricky as
    # we can't make sure we click the right checkbox)
    send_key "tab";
    send_key "tab";
    send_key "tab";
    # check it
    send_key "spc";
    # select the right arrow
    send_key "tab";
    # click it
    send_key "ret";
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
    $self->console_login(user=>'test3@DOMAIN.LOCAL', password=>'batterystaple');
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
    # back to tty1 to let generic freeipa_client test pick up from here
    send_key "ctrl-alt-f1";
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return {};
}

1;
