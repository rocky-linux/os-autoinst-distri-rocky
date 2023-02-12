use base "installedtest";
use strict;
use testapi;
use tapnet;
use utils;

sub run {
    my $self = shift;
    my ($ip, $hostname) = split(/ /, get_var("POST_STATIC"));
    $hostname //= 'localhost.localdomain';
    # set up networking
    setup_tap_static($ip, $hostname);
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
