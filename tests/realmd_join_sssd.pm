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
    assert_script_run "sed -i -e '/^DNS.*/d' /etc/sysconfig/network-scripts/ifcfg-eth0";
    assert_script_run "printf '\nDNS1=10.0.2.100\n' >> /etc/sysconfig/network-scripts/ifcfg-eth0";
    # wait for the server to be ready (do it now just to make sure name
    # resolution is working before we proceed)
    mutex_lock "freeipa_ready";
    mutex_unlock "freeipa_ready";
    # use compose repo, disable u-t, etc. unless this is an upgrade
    # test (in which case we're on the 'old' release at this point;
    # one of the upgrade test modules does repo_setup later)
    repo_setup() unless get_var("UPGRADE");
    # do the enrolment
    assert_script_run "echo 'monkeys123' | realm join --user=admin ipa001.domain.local", 300;
    # set sssd debugging level higher (useful for debugging failures)
    # optional as it's not really part of the test
    script_run "dnf -y install sssd-tools", 180;
    script_run "sss_debuglevel 6";
    # if upgrade test, report that we're enrolled
    mutex_create('client_enrolled') if get_var("UPGRADE");
    # if this is an upgrade test, wait for server to be upgraded before
    # continuing, as we rely on it for name resolution
    if (get_var("UPGRADE")) {
        mutex_lock "server_upgraded";
        mutex_unlock "server_upgraded";
    }
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
