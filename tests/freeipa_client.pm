use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $ipa_domain = 'test.openqa.rockylinux.org';
    my $ipa_realm = 'TEST.OPENQA.ROCKYLINUX.ORG';

    # Rocky SUT is graphical so stay on/force tty3 do NOT switch to tty1
    $self->root_console(tty => 3);
    wait_still_screen 1;

    # check domain is listed in 'realm list'
    validate_script_output 'realm list', sub { $_ =~ m/domain-name: test\.openqa\.rockylinux\.org.*configured: kerberos-member/s };
    # check we can see the admin user in getent
    assert_script_run "getent passwd admin\@$ipa_realm";
    # check keytab entries
    my $hostname = script_output 'hostname';
    my $qhost = quotemeta($hostname);
    validate_script_output 'klist -k', sub { $_ =~ m/$qhost\@TEST\.OPENQA\.ROCKYLINUX\.ORG/ };
    # check we can kinit with the host principal
    assert_script_run "kinit -k host/$hostname\@$ipa_realm";
    # Set a longer timeout for login(1) to workaround RHBZ #1661273
    assert_script_run 'echo "LOGIN_TIMEOUT 180" >> /etc/login.defs';
    # switch to tty2 for login tests
    send_key "ctrl-alt-f2";
    # try and login as test1, should work
    console_login(user => 'test1@TEST.OPENQA.ROCKYLINUX.ORG', password => 'batterystaple');
    type_string "exit\n";
    # try and login as test2, should fail. we cannot use console_login
    # as it takes 10 seconds to complete when login fails, and
    # "permission denied" message doesn't last that long
    sleep 2;
    assert_screen "text_console_login";
    type_string "test2\@$ipa_realm\n";
    assert_screen "console_password_required";
    type_string "batterystaple\n";
    assert_screen "login_permission_denied";
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
