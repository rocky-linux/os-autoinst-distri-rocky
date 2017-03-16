use base "installedtest";
use strict;
use testapi;
use lockapi;
use tapnet;
use utils;

sub run {
    my $self=shift;
    # use FreeIPA server as DNS server
    assert_script_run "printf 'search domain.local\nnameserver 10.0.2.100' > /etc/resolv.conf";
    # wait for the server to be ready (do it now just to make sure name
    # resolution is working before we proceed)
    mutex_lock "freeipa_ready";
    mutex_unlock "freeipa_ready";
    # use compose repo, disable u-t, etc.
    repo_setup();
    # do the enrolment
    assert_script_run "echo 'monkeys123' | realm join --user=admin ipa001.domain.local", 300;
    # set sssd debugging level higher (useful for debugging failures)
    # optional as it's not really part of the test
    script_run "dnf -y install sssd-tools", 180;
    script_run "sss_debuglevel 6";
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
