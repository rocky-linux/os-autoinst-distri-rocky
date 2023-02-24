use base "basetest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    send_key "ctrl-alt-f3";
    # do user login unless USER_LOGIN is set to string 'false'
    # Since there is no console support for arabic, so we cannot let the user log in
    # with a password that requires Arabic support.
    # Such attempt to log in would always fail.
    if (get_var("LANGUAGE") ne "arabic" && get_var("USER_LOGIN") ne "false") {
        console_login(user => get_var("USER_LOGIN", "test"), password => get_var("USER_PASSWORD", "weakpassword"));
    }
    if (get_var("ROOT_PASSWORD")) {
        console_login(user => "root", password => get_var("ROOT_PASSWORD"));
    }
}
sub test_flags {
    return {fatal => 1, milestone => 1};
}
1;
# vim: set sw=4 et:
