use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->root_console(tty=>4);
    # support switching to stg repos
    dnf_contentdir();
    assert_script_run 'top -i -n20 -b > /var/tmp/top.log', 120;
    upload_logs '/var/tmp/top.log';
    unless (get_var("CANNED")) {
        assert_script_run 'rpm -qa --queryformat "%{NAME}\n" | sort -u > /var/tmp/rpms.log';
        upload_logs '/var/tmp/rpms.log';
        # installed packages as CSV with separated NEVRA
        assert_script_run 'rpm -qa --queryformat="%{NAME},%{EPOCH},%{VERSION},%{RELEASE},%{ARCH}\n" | sort > /var/tmp/rpms.nevra.csv';
        upload_logs '/var/tmp/rpms.nevra.csv';
    }
    assert_script_run 'free > /var/tmp/free.log';
    upload_logs '/var/tmp/free.log';
    assert_script_run 'df > /var/tmp/df.log';
    upload_logs '/var/tmp/df.log';
    assert_script_run 'systemctl -t service --no-pager --no-legend | grep -o "[[:graph:]]*\.service" > /var/tmp/services.log';
    upload_logs '/var/tmp/services.log';

    # Record default (or non-default) partitioning
    assert_script_run 'lsblk > /var/tmp/lsblk.log';
    upload_logs '/var/tmp/lsblk.log';

    # Record selected group
    assert_script_run 'dnf group list --verbose > /var/tmp/dnf-group-list.log';
    upload_logs '/var/tmp/dnf-group-list.log';

    # Collect all combinations of modules
    assert_script_run 'dnf module list --enabled > /var/tmp/dnf-module-list-enabled.log';
    upload_logs '/var/tmp/dnf-module-list-enabled.log';
    assert_script_run 'dnf module list --disabled > /var/tmp/dnf-module-list-disabled.log';
    upload_logs '/var/tmp/dnf-module-list-disabled.log';
    assert_script_run 'dnf module list --installed > /var/tmp/dnf-module-list-installed.log';
    upload_logs '/var/tmp/dnf-module-list-installed.log';
    assert_script_run 'dnf module list --available > /var/tmp/dnf-module-list-available.log';
    upload_logs '/var/tmp/dnf-module-list-available.log';
    assert_script_run 'dnf module list --all > /var/tmp/dnf-module-list-all.log';
    upload_logs '/var/tmp/dnf-module-list-all.log';
}

sub test_flags {
    return { 'ignore_failure' => 1 };
}

1;

# vim: set sw=4 et:
