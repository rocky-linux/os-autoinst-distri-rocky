use base "installedtest";
use strict;
use testapi;
use lockapi;
use tapnet;
use utils;

sub run {
    my $self=shift;
    # clone host's /etc/hosts (for phx2 internal routing to work)
    # must come *before* setup_tap_static or else it would overwrite
    # its changes
    clone_host_file("/etc/hosts");
    # set up networking
    setup_tap_static("10.0.2.105", "dbclient.domain.local");
    # clone host's resolv.conf to get name resolution
    clone_host_file("/etc/resolv.conf");
    # use compose repo, disable u-t, etc.
    repo_setup();
    # install postgresql
    assert_script_run "dnf -y install postgresql", 120;
    # wait for the server to be ready
    mutex_lock "db_ready";
    mutex_unlock "db_ready";
    # check we can connect to the database and create a table
    assert_script_run "PGPASSWORD=correcthorse psql openqa -h 10.0.2.104 -U openqa -c 'CREATE TABLE test2 (testcol int);'";
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
