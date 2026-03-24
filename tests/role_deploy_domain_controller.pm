use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

# Adapted from Fedora's OpenQA tests, with some modifications. This will need
# to be maintained per major version as necessary.
# label@rockylinux.org

use feature "switch";

sub run {
    my $self = shift;
    my $version_major = get_version_major;
    my $relnum = get_release_number;
    my $ipa_hostname = script_output 'hostname';
    my $ipa_install_cmd;
    my @ipa_firewall_services;
    my $ipa_domain = get_var("REALMD_DOMAIN", "test.openqa.rockylinux.org");
    my $ipa_realm = get_var("REALMD_REALM", "TEST.OPENQA.ROCKYLINUX.ORG");
    my $ipa_admin_password = get_var("REALMD_ADMIN_PASSWORD", 'b1U3OnyX!');
    my $ipa_admin_user = get_var("REALMD_ADMIN_USER", 'admin');
    my $ipa_reverse_zone = '2.16.172.in-addr.arpa';
    my $ipa_install_args = "-U --auto-forwarders --realm=$ipa_realm --domain=$ipa_domain --ds-password=$ipa_admin_password --admin-password=$ipa_admin_password --setup-dns --reverse-zone=$ipa_reverse_zone --allow-zone-overlap --skip-mem-check";
    given ($version_major) {
        when ('8') {
            $ipa_install_cmd = 'dnf --assumeyes module install idm:DL1/{dns,client,server,common}';
            @ipa_firewall_services = qw(http https kerberos kpasswd ldap ldaps dns);
        }
        when ('9') {
            $ipa_install_cmd = 'dnf --assumeyes install ipa-server ipa-client ipa-server-dns sssd sssd-ipa';
            @ipa_firewall_services = qw(freeipa-4 dns);
        }
        default {
            $ipa_install_cmd = 'dnf --assumeyes install ipa-server ipa-client ipa-server-dns sssd sssd-ipa';
            @ipa_firewall_services = qw(freeipa-4 dns);
        }
    }

    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);

    if (get_var("ROOT_PASSWORD")) {
        console_login(user => "root", password => get_var("ROOT_PASSWORD"));
    }

    # We need entropy. Install rng-tools and start it up. Fedora uses haveged
    # but Rocky Linux does not have it unless EPEL is used.
    assert_script_run "dnf --assumeyes install rng-tools", 300;
    assert_script_run 'systemctl start rngd.service';
    # per ab, this should get us extra debug logging from the web UI
    # in error_log
    assert_script_run 'mkdir -p /etc/ipa';
    assert_script_run 'printf "[global]\ndebug = True\n" > /etc/ipa/server.conf';
    # per ab, this gets us more debugging for bind
    assert_script_run 'mkdir -p /etc/systemd/system/named-pkcs11.service.d';
    assert_script_run 'printf "[Service]\nEnvironment=OPTIONS=-d5\n" > /etc/systemd/system/named-pkcs11.service.d/debug.conf';
    # Based on the major version, install FreeIPA
    assert_script_run "$ipa_install_cmd", 600;
    # Enable all the firewall services as needed per major version
    for my $service (@ipa_firewall_services) {
        assert_script_run "firewall-cmd --permanent --add-service $service";
    }
    assert_script_run "systemctl restart firewalld.service";
    # deploy the server
    assert_script_run "ipa-server-install $ipa_install_args", 1200;
    # enable and start the systemd service
    assert_script_run "systemctl enable ipa.service";
    assert_script_run "systemctl start ipa.service", 300;

    # kinit as admin
    assert_script_run "echo '$ipa_admin_password' | kinit $ipa_admin_user";
    # set up an OTP for client001 enrolment (this should enroll by kickstart or another way)
    assert_script_run "ipa host-add client001.$ipa_domain --password=monkeys --force";
    ############################################################################
    # Testing kerb services
    assert_script_run "ipa service-add testservice/$ipa_hostname";
    assert_script_run "ipa-getkeytab -s $ipa_hostname -p testservice/$ipa_hostname -k /tmp/testservice.keytab";
    validate_script_output 'klist -k /tmp/testservice.keytab', sub { $_ =~ m/testservice\/$ipa_hostname/ };
    # This is commented for now. We need a while loop that watches for ipa-getcert list -r to become empty.
#assert_script_run "ipa-getcert request -K testservice/$ipa_hostname -D $ipa_hostname -f /etc/pki/tls/certs/testservice.pki -k /etc/pki/tls/private/testservice.key";
    #validate_script_output "ipa-getcert list -r | sed -n '/Request ID/,/auto-renew: yes/p'", sub { $_ =~ m// };

    ############################################################################
    # Testing DNS
    assert_script_run "ipa dnszone-add --name-server=$ipa_hostname. --admin-email=hostmaster.testzone.$ipa_domain. testzone.$ipa_domain";
    sleep(5);
    # ensure subdomain was made
    validate_script_output "dig \@localhost SOA testzone.$ipa_domain", sub { $_ =~ m/status: NOERROR/ };
    # make test records with CNAME
    assert_script_run "ipa dnsrecord-add $ipa_domain testrecord --cname-hostname=onyxtest";
    # validate it works
    validate_script_output "dig \@localhost CNAME testrecord.$ipa_domain", sub { $_ =~ m/status: NOERROR/ };
    # make test records with CNAME in subdomain
    assert_script_run "ipa dnsrecord-add testzone.$ipa_domain testrecord --cname-hostname=onyxtest.$ipa_domain";
    # validate it works
    validate_script_output "dig \@localhost CNAME testrecord.testzone.$ipa_domain", sub { $_ =~ m/status: NOERROR/ };

    ############################################################################
    # User Accounts + HBAC + SUDO
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
    assert_script_run "ipa dnszone-mod $ipa_domain. --allow-sync-ptr=TRUE";
    # kinit as each user and set a new password
    assert_script_run "printf 'correcthorse\nbatterystaple\nbatterystaple' | kinit test1\@$ipa_realm";
    assert_script_run "printf 'correcthorse\nbatterystaple\nbatterystaple' | kinit test2\@$ipa_realm";

    # add a sudo rule
    assert_script_run "kswitch -p $ipa_admin_user\@$ipa_realm";
    assert_script_run 'ipa sudorule-add testrule --desc="Test rule in IPA" --hostcat=all --cmdcat=all --runasusercat=all --runasgroupcat=all';
    assert_script_run 'ipa sudorule-add-user testrule --users="test1"';
    validate_script_output 'ipa sudorule-show testrule', sub { $_ =~ m/Rule name: testrule/ };
    validate_script_output 'ipa sudorule-show testrule', sub { $_ =~ m/Users: test1/ };
    # This may fail - Invalidate sudo cache and check test1's sudo perms
    # If we want to test this in openQA it appears we may need to deploy more complete
    # config for sudo. For now change validate_script_output to assert_script_run
    assert_script_run 'sss_cache -R';
    #validate_script_output 'sudo -l -U test1', sub { $_ =~ m/test1 may run the following commands/ };
    assert_script_run 'sudo -l -U test1';

    # we're ready for children to enroll, now
    mutex_create("freeipa_ready");
    # This generally applies to Fedora upgrades. We don't perform upgrades in EL
    # but we will leave this here.
    if (get_var("UPGRADE")) {
        my $children = get_children();
        my $child_id = (keys %$children)[0];
        mutex_lock('client_enrolled', $child_id);
        mutex_unlock('client_enrolled');
    }
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
