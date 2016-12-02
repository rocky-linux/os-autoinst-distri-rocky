use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    $self->root_console(tty=>3);
    assert_script_run 'top -i -n20 -b > /var/tmp/top.log';
    upload_logs '/var/tmp/top.log';
    assert_script_run 'rpm -qa --queryformat "%{NAME}\n" | sort -u > /var/tmp/rpms.log';
    upload_logs '/var/tmp/rpms.log';
    assert_script_run 'free > /var/tmp/free.log';
    upload_logs '/var/tmp/free.log';
    assert_script_run 'df > /var/tmp/df.log';
    upload_logs '/var/tmp/df.log';
    assert_script_run 'systemctl -t service --no-pager |grep -o ".*\.service" > /var/tmp/services.log';
    upload_logs '/var/tmp/services.log';
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return {};
}

1;

# vim: set sw=4 et:
