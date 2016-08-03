package freeipa;

use strict;

use base 'Exporter';
use Exporter;

use testapi;

our @EXPORT = qw/add_user start_webui/;

# add a user with given username and surname, always uses the password
# "correcthorse". Assumes FreeIPA web UI is showing the Users screen.
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

# access the FreeIPA web UI and log in as a given user. Assumes
# Firefox is running.
sub start_webui {
    my ($user, $password) = @_;
    # new tab
    send_key "ctrl-t";
    wait_still_screen 2;
    type_string "https://ipa001.domain.local";
    # firefox's stupid 'smart' url bar is a pain. wait for things to settle.
    wait_still_screen 3;
    send_key "ret";
    assert_screen "freeipa_webui_login";
    type_string $user;
    wait_still_screen 1;
    send_key "tab";
    wait_still_screen 1;
    type_string $password;
    wait_still_screen 1;
    send_key "ret";
    # if we logged in as 'admin' we should land on the admin 'Active
    # users' screen, otherwise we should land on the user's own page
    $user eq 'admin' ? assert_screen "freeipa_webui_users" : assert_screen "freeipa_webui_user";
}
