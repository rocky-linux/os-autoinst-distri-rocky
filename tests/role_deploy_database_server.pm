use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

sub run {
    my $self=shift;
    clone_host_file("/etc/hosts");
    # set up networking
    setup_tap_static("10.0.2.104", "db.domain.local");
    # clone host's resolv.conf to get name resolution
    clone_host_file("/etc/resolv.conf");
    # use compose repo, disable u-t, etc.
    repo_setup();
    # deploy the database server role
    assert_script_run 'echo \'{"database":"openqa","owner":"openqa","password":"correcthorse"}\' | rolectl deploy databaseserver --settings-stdin', 300;
    # check the role status, should be 'running'
    validate_script_output 'rolectl status databaseserver/1', sub { $_ =~ m/^running/ };
    # check 'settings' output looks vaguely right
    validate_script_output 'rolectl settings databaseserver/1', sub {$_ =~ m/owner = openqa/ };
    # check we can connect to the database and create a table
    assert_script_run 'su postgres -c "psql openqa -c \'CREATE TABLE test (testcol int);\'"';
    # check we can add a row to the table
    assert_script_run 'su postgres -c "psql openqa -c \'INSERT INTO test VALUES (5);\'"';
    # check we can query the table
    validate_script_output 'su postgres -c "psql openqa -c \'SELECT * FROM test;\'"', sub {$_ =~ m/^ *testcol.*5.*1 row/s };
    # check we can modify the row
    assert_script_run 'su postgres -c "psql openqa -c \'UPDATE test SET testcol = 50 WHERE testcol = 5;\'"';
    validate_script_output 'su postgres -c "psql openqa -c \'SELECT * FROM test;\'"', sub {$_ =~ m/^ *testcol.*50.*1 row/s };
    # we're all ready for other jobs to run!
    mutex_create('db_ready');
    wait_for_children;
    # once child jobs are done, stop the role
    assert_script_run 'rolectl stop databaseserver/1';
    # check role is stopped
    validate_script_output 'rolectl status databaseserver/1', sub { $_ =~ m/^ready-to-start/ };
    # decommission the role
    assert_script_run 'rolectl decommission databaseserver/1', 120;
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
