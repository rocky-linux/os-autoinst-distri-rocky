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
    type_string "startx /usr/bin/firefox -width 1024 -height 768 https://ipa001.domain.local\n";
    wait_still_screen 5;
    assert_screen "freeipa_webui_login";
    type_safely $user;
    wait_screen_change { send_key "tab"; };
    type_safely $password;
    send_key "ret";
    # if we logged in as 'admin' we should land on the admin 'Active
    # users' screen, otherwise we should land on the user's own page
    $user eq 'admin' ? assert_screen "freeipa_webui_users" : assert_screen "freeipa_webui_user";
    wait_still_screen 3;
}
