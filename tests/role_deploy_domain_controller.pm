use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;

sub run {
    my $self=shift;
    # boot with kernel params to ensure interface is 'eth0' and not whatever
    # systemd feels like calling it today
    $self->do_bootloader(1, "net.ifnames=0 biosdevname=0");
    $self->boot_to_login_screen("text_console_login", 5, 60);
    # login
    $self->root_console();
    # set hostname
    assert_script_run 'hostnamectl set-hostname ipa001.domain.local';
    # add entry to /etc/hosts
    assert_script_run 'echo "10.0.2.100 ipa001.domain.local ipa001" >> /etc/hosts';
    # bring up network. DEFROUTE is *vital* here
    assert_script_run 'printf "DEVICE=eth0\nBOOTPROTO=none\nIPADDR=10.0.2.100\nGATEWAY=10.0.2.2\nPREFIX=24\nDEFROUTE=yes" > /etc/sysconfig/network-scripts/ifcfg-eth0';
    script_run "systemctl restart NetworkManager.service";
    # clone host's resolv.conf to get name resolution
    $self->clone_host_resolv();
    # we don't want updates-testing for validation purposes
    assert_script_run 'dnf config-manager --set-disabled updates-testing';
    # we need a lot of entropy for this, and we don't care how good
    # it is, so let's use haveged
    assert_script_run 'dnf -y install haveged', 120;
    assert_script_run 'systemctl start haveged.service';
    # deploy the domain controller role
    assert_script_run 'echo \'{"admin_password":"monkeys123"}\' | rolectl deploy domaincontroller --name=domain.local --settings-stdin', 1200;
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
    # we're all ready for other jobs to run!
    mutex_create('freeipa_ready');
    wait_for_children;
    # once child jobs are done, stop the role
    assert_script_run 'rolectl stop domaincontroller/domain.local';
    # check role is stopped
    validate_script_output 'rolectl status domaincontroller/domain.local', sub { $_ =~ m/^ready-to-start/ };
    # decommission the role
    assert_script_run 'rolectl decommission domaincontroller/domain.local', 120;
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
