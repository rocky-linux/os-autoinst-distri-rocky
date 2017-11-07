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
    # we need a lot of entropy for this, and we don't care how good
    # it is, so let's use haveged
    unless (get_var("MODULAR")) {
        assert_script_run 'dnf -y install haveged', 300;
        assert_script_run 'systemctl start haveged.service';
    }
    # read DNS server IPs from host's /etc/resolv.conf for passing to
    # rolectl
    my @forwards = get_host_dns();
    # we are now gonna work around a stupid bug in rolekit. we want to
    # pass it a list of ipv4 DNS forwarders and have no ipv6 DNS
    # forwarders. but it won't allow you to have a dns_forwarders array
    # with a "ipv4" list but no "ipv6" list, any values in the "ipv6"
    # list must be contactable (so we can't use real IPv6 DNS servers
    # as we have no IPv6 connectivity), and if you use an empty list
    # as the "ipv6" value you often hit a weird DBus error "unable to
    # guess signature from an empty list". Fortunately, rolekit doesn't
    # actually check that the values in the lists are really IPv6 /
    # IPv4, it just turns all the values in each list into --forwarder
    # args for ipa-server-install. So we can just stuff IPv4 values
    # into both lists. rolekit bug:
    # https://github.com/libre-server/rolekit/issues/64
    # it should be fixed relatively soon.
    my $fourlist;
    my $sixlist;
    if (scalar @forwards == 1) {
        # we've only got one server, so dupe it, best we can do
        $fourlist = '["' . $forwards[0] . '"]';
        $sixlist = $fourlist;
    }
    else {
        # put the first value in the 'IPv4' list and all the others in
        # the 'IPv6' list
        $fourlist = '["' . shift(@forwards) . '"]';
        $sixlist = '["' . join('","', @forwards) . '"]';
    }
    # deploy the domain controller role, specifying an admin password
    # and the list of DNS server IPs as JSON via stdin. If we don't do
    # this, rolectl defaults to using the root servers as forwarders
    # (it does not copy the settings from resolv.conf), which give the
    # public results for mirrors.fedoraproject.org, some of which
    # things running in phx2 cannot reach; we must make sure the phx2
    # deployments use the phx2 nameservers.
    assert_script_run 'echo \'{"admin_password":"monkeys123","dns_forwarders":{"ipv4":' . $fourlist . ',"ipv6":' . $sixlist .'}}\' | rolectl deploy domaincontroller --name=domain.local --settings-stdin', 1200;
    # FIXME: workaround for RHBZ #1400293 on Fedora 24. Can be removed
    # when Firefox is fixed.
    my $release = lc(get_var('VERSION'));
    if ($release ne "rawhide" && $release < 25) {
        assert_script_run 'ipa-getcert resubmit -d /etc/httpd/alias -n Server-Cert -D $( uname -n )';
    }
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
