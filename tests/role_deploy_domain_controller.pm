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
    # clone host's /etc/hosts (for phx2 internal routing to work)
    # must come *before* setup_tap_static or else it would overwrite
    # its changes
    clone_host_file("/etc/hosts");
    # set up networking
    setup_tap_static("10.0.2.100", "ipa001.domain.local");
    # clone host's resolv.conf to get name resolution
    clone_host_file("/etc/resolv.conf");
    # use compose repo, disable u-t, etc.
    repo_setup();
    # we need a lot of entropy for this, and we don't care how good
    # it is, so let's use haveged
    assert_script_run 'dnf -y install haveged', 300;
    assert_script_run 'systemctl start haveged.service';
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
    # check the role status, should be 'running'
    validate_script_output 'rolectl status domaincontroller/domain.local', sub { $_ =~ m/^running/ };
    # check the admin password is listed in 'settings'
    validate_script_output 'rolectl settings domaincontroller/domain.local', sub {$_ =~m/dm_password = \w{5,}/ };
    # sanitize the settings
    assert_script_run 'rolectl sanitize domaincontroller/domain.local';
    # check the password now shows as 'None'
    validate_script_output 'rolectl settings domaincontroller/domain.local', sub {$_ =~ m/dm_password = None/ };
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
    # we're all ready for other jobs to run!
    mutex_create('freeipa_ready');
    wait_for_children;
    # once child jobs are done, stop the role
    assert_script_run 'rolectl stop domaincontroller/domain.local';
    # check role is stopped
    validate_script_output 'rolectl status domaincontroller/domain.local', sub { $_ =~ m/^ready-to-start/ };
    # decommission the role
    assert_script_run 'rolectl decommission domaincontroller/domain.local', 300;
    # check role is decommissioned
    validate_script_output 'rolectl list instances', sub { $_ eq "" };
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
