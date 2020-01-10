use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

sub run {
    my $self = shift;
    # login
    $self->root_console();
    # use compose repo, disable u-t, etc. unless this is an upgrade
    # test (in which case we're on the 'old' release at this point;
    # one of the upgrade test modules does repo_setup later)
    repo_setup() unless get_var("UPGRADE");
    # use --enablerepo=fedora for Modular compose testing (we need to
    # create and use a non-Modular repo to get some packages which
    # aren't in Modular Server composes)
    my $extraparams = '';
    $extraparams = '--enablerepo=fedora' if (get_var("MODULAR"));
    # we need a lot of entropy for this, and we don't care how good
    # it is, so let's use haveged
    assert_script_run "dnf ${extraparams} -y install haveged", 300;
    assert_script_run 'systemctl start haveged.service';
    # per ab, this should get us extra debug logging from the web UI
    # in error_log
    assert_script_run 'mkdir -p /etc/ipa';
    assert_script_run 'printf "[global]\ndebug = True\n" > /etc/ipa/server.conf';
    # per ab, this gets us more debugging for bind
    assert_script_run 'mkdir -p /etc/systemd/system/named-pkcs11.service.d';
    assert_script_run 'printf "[Service]\nEnvironment=OPTIONS=-d5\n" > /etc/systemd/system/named-pkcs11.service.d/debug.conf';
    # read DNS server IPs from host's /etc/resolv.conf for passing to
    # ipa-server-install / rolectl
    my @forwards = get_host_dns();
    # First install the necessary packages
    assert_script_run "dnf -y groupinstall freeipa-server", 600;
    # configure the firewall
    for my $service (qw(freeipa-ldap freeipa-ldaps dns)) {
        assert_script_run "firewall-cmd --permanent --add-service $service";
    }
    assert_script_run "systemctl restart firewalld.service";
    # deploy the server
    my $args = "-U --realm=DOMAIN.LOCAL --domain=domain.local --ds-password=monkeys123 --admin-password=monkeys123 --setup-dns --reverse-zone=2.0.10.in-addr.arpa --allow-zone-overlap";
    for my $fwd (@forwards) {
        $args .= " --forwarder=$fwd";
    }
    assert_script_run "ipa-server-install $args", 1200;
    # enable and start the systemd service
    assert_script_run "systemctl enable ipa.service";
    assert_script_run "systemctl start ipa.service", 300;

    # kinit as admin
    assert_script_run 'echo "monkeys123" | kinit admin';
    # set up an OTP for client001 enrolment (it will enrol with a kickstart)
    assert_script_run 'ipa host-add client001.domain.local --password=monkeys --force';
    # create two user accounts, test1 and test2
    assert_script_run 'echo "correcthorse" | ipa user-add test1 --first test --last one --password';
    assert_script_run 'echo "correcthorse" | ipa user-add test2 --first test --last two --password';
    # add a rule allowing access to all hosts and services
    assert_script_run 'ipa hbacrule-add testrule --servicecat=all --hostcat=all';
    # add test1 (but not test2) to the rule
    assert_script_run 'ipa hbacrule-add-user testrule --users=test1';
    # disable the default 'everyone everywhere' rule
    assert_script_run 'ipa hbacrule-disable allow_all';
    # allow immediate password changes (as we need to test this)
    assert_script_run 'ipa pwpolicy-mod --minlife=0';
    # magic voodoo crap to allow reverse DNS client sync to work
    # https://docs.pagure.org/bind-dyndb-ldap/BIND9/SyncPTR.html
    assert_script_run 'ipa dnszone-mod domain.local. --allow-sync-ptr=TRUE';
    # kinit as each user and set a new password
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test1@DOMAIN.LOCAL';
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test2@DOMAIN.LOCAL';
    # we're ready for children to enrol, now
    mutex_create("freeipa_ready");
    # if upgrade test, wait for children to enrol before upgrade
    if (get_var("UPGRADE")) {
        my $children = get_children();
        my $child_id = (keys %$children)[0];
        mutex_lock('client_enrolled', $child_id);
        mutex_unlock('client_enrolled');
    }
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
