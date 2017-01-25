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
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
