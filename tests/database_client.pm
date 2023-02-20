use base "installedtest";
use strict;
use testapi;
use lockapi;
use tapnet;
use utils;

sub run {
    my $self = shift;
    # use compose repo, disable u-t, etc.
    repo_setup();
    # install postgresql
    assert_script_run "dnf -y install postgresql", 160;
    # wait for the server to be ready
    mutex_lock "db_ready";
    mutex_unlock "db_ready";
    # check we can connect to the database and create a table
    assert_script_run "PGPASSWORD=correcthorse psql openqa -h 172.16.2.104 -U openqa -c 'CREATE TABLE test2 (testcol int);'";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
