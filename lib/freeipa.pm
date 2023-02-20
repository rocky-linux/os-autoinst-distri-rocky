package freeipa;

use strict;

use base 'Exporter';
use Exporter;

use testapi;
use utils;

our @EXPORT = qw/add_user start_webui/;

# add a user with given username and surname, always uses the password
# "correcthorse". Assumes FreeIPA web UI is showing the Users screen.
sub add_user {
    my ($user, $surname) = @_;
    wait_still_screen 1;
    assert_and_click "freeipa_webui_add_button";
    assert_screen "freeipa_webui_add_user";
    wait_still_screen 1;
    type_safely $user;
    wait_screen_change { send_key "tab"; };
    # we don't need to be too careful here as the names don't matter
    type_safely "Test";
    wait_screen_change { send_key "tab"; };
    type_safely $surname;
    type_safely "\t\t\t\t";
    type_safely "correcthorse";
    wait_screen_change { send_key "tab"; };
    type_safely "correcthorse\n";
}

# access the FreeIPA web UI and log in as a given user. Assumes
# it's at a console ready to start Firefox.
sub start_webui {
    my ($user, $password) = @_;
    # if we logged in as 'admin' we should land on the admin 'Active
    # users' screen, otherwise we should land on the user's own page
    my $user_screen = "freeipa_webui_user";
    $user_screen = "freeipa_webui_users" if ($user eq 'admin');

    # https://bugzilla.redhat.com/show_bug.cgi?id=1439429
    assert_script_run "sed -i -e 's,enable_xauth=1,enable_xauth=0,g' /usr/bin/startx";
    disable_firefox_studies;
    type_string "startx /usr/bin/firefox -width 1024 -height 768 https://ipa001.test.openqa.fedoraproject.org\n";
    assert_screen ["freeipa_webui_login", $user_screen], 60;
    wait_still_screen(stilltime => 5, similarity_level => 45);
    # softfail on kerberos ticket bugs meaning we get auto-logged in
    # as the requested user when we don't expect to be
    if (match_has_tag $user_screen) {
        record_soft_failure "already logged in to web UI";
    }
    else {
        type_safely $user;
        wait_screen_change { send_key "tab"; };
        type_safely $password;
        send_key "ret";
        assert_screen $user_screen;
    }
    wait_still_screen 3;
}
