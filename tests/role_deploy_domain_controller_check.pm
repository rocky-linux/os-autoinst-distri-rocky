use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;

sub run {
    my $self = shift;
    # if this is an update, notify clients that we're now up again
    mutex_create('server_upgraded') if get_var("UPGRADE");
    # check the role status, should be 'running'
    validate_script_output 'rolectl status domaincontroller/domain.local', sub { $_ =~ m/^running/ };
    # check the admin password is listed in 'settings'
    validate_script_output 'rolectl settings domaincontroller/domain.local', sub {$_ =~m/dm_password = \w{5,}/ };
    # sanitize the settings
    assert_script_run 'rolectl sanitize domaincontroller/domain.local';
    # check the password now shows as 'None'
    validate_script_output 'rolectl settings domaincontroller/domain.local', sub {$_ =~ m/dm_password = None/ };
    # once child jobs are done, stop the role
    wait_for_children;
    assert_script_run 'rolectl stop domaincontroller/domain.local';
    # check role is stopped
    validate_script_output 'rolectl status domaincontroller/domain.local', sub { $_ =~ m/^ready-to-start/ };
    # decommission the role
    assert_script_run 'rolectl decommission domaincontroller/domain.local', 300;
    # check role is decommissioned
    validate_script_output 'rolectl list instances', sub { $_ eq "" };
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
