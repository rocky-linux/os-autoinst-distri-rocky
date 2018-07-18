use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

sub run {
    my $self=shift;
    # use FreeIPA server or replica as DNS server
    my $server = 'ipa001.domain.local';
    my $server_ip = '10.0.2.100';
    my $server_mutex = 'freeipa_ready';
    if (get_var("FREEIPA_REPLICA")) {
        $server = 'ipa002.domain.local';
        $server_ip = '10.0.2.106';
    }
    if (get_var("FREEIPA_REPLICA_CLIENT")) {
        $server = 'ipa003.domain.local';
        $server_ip = '10.0.2.107';
        $server_mutex = 'replica_ready';
    }
    assert_script_run "printf 'search domain.local\nnameserver ${server_ip}' > /etc/resolv.conf";
    assert_script_run "sed -i -e '/^DNS.*/d' /etc/sysconfig/network-scripts/ifcfg-eth0";
    assert_script_run "printf '\nDNS1=${server_ip}\n' >> /etc/sysconfig/network-scripts/ifcfg-eth0";
    # wait for the server or replica to be ready (do it now just to be
    # sure name resolution is working before we proceed)
    mutex_lock $server_mutex;
    mutex_unlock $server_mutex;
    # use compose repo, disable u-t, etc. unless this is an upgrade
    # test (in which case we're on the 'old' release at this point;
    # one of the upgrade test modules does repo_setup later)
    repo_setup() unless get_var("UPGRADE");
    # do the enrolment
    if (get_var("FREEIPA_REPLICA")) {
        # here we're enrolling not just as a client, but as a replica
        # install server packages
        assert_script_run "dnf -y groupinstall freeipa-server", 600;

        # we need a lot of entropy for this, and we don't care how good
        # it is, so let's use haveged
        assert_script_run "dnf -y install haveged", 300;
        assert_script_run 'systemctl start haveged.service';

        # read DNS server IPs from host's /etc/resolv.conf for passing to
        # ipa-replica-install
        my @forwards = get_host_dns();

        # configure the firewall
        for my $service (qw(freeipa-ldap freeipa-ldaps dns)) {
            assert_script_run "firewall-cmd --permanent --add-service $service";
        }
        assert_script_run "systemctl restart firewalld.service";

        # deploy as a replica
        my $args = "--setup-dns --setup-ca --allow-zone-overlap -U --principal admin --admin-password monkeys123";
        for my $fwd (@forwards) {
            $args .= " --forwarder=$fwd";
        }
        assert_script_run "ipa-replica-install $args", 1200;

        # don't use the other server for our DNS lookups any more, as we
        # should be independent of it
        my ($ip, $hostname) = split(/ /, get_var("POST_STATIC"));
        setup_tap_static($ip, $hostname);

        # enable and start the systemd service
        assert_script_run "systemctl enable ipa.service";
        assert_script_run "systemctl start ipa.service", 300;

        # report that we're ready to go
        mutex_create('replica_ready');

        # wait for the client test
        wait_for_children;
    }
    else {
        assert_script_run "echo 'monkeys123' | realm join --user=admin ${server}", 300;
    }
    # set sssd debugging level higher (useful for debugging failures)
    # optional as it's not really part of the test
    script_run "dnf -y install sssd-tools", 220;
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
