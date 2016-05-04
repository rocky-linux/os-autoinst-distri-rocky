use base "installedtest";
use strict;
use testapi;

sub run {
    my $self=shift;
    # check domain is listed in 'realm list'
    validate_script_output 'realm list', sub { $_ =~ m/domain-name: domain\.local.*configured: kerberos-member/s };
    # check we can see the admin user in getent
    assert_script_run 'getent passwd admin@DOMAIN.LOCAL';
    # check keytab entries
    validate_script_output 'klist -k', sub { $_ =~ m/client001\.domain\.local\@DOMAIN.LOCAL/ };
    # check we can kinit with the host principal
    assert_script_run 'kinit -k host/client001.domain.local@DOMAIN.LOCAL';
    # kinit as each user and set a new password
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test1@DOMAIN.LOCAL';
    assert_script_run 'printf "correcthorse\nbatterystaple\nbatterystaple" | kinit test2@DOMAIN.LOCAL';
    # switch to tty3
    send_key "ctrl-alt-f3";
    # try and login as test1, should work
    $self->console_login(user=>'test1@DOMAIN.LOCAL', password=>'batterystaple');
    type_string "exit\n";
    # try and login as test2, should fail. we cannot use console_login
    # as it takes 10 seconds to complete when login fails, and
    # "permission denied" message doesn't last that long
    sleep 2;
    assert_screen "text_console_login";
    type_string "test2\@DOMAIN.LOCAL\n";
    assert_screen "console_password_required";
    type_string "batterystaple\n";
    assert_screen "login_permission_denied";
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
