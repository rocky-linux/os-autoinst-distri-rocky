use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

sub run {
    my $self=shift;
    # use compose repo, disable u-t, etc.
    repo_setup();
    # deploy postgres directly ourselves. first, install packages...
    assert_script_run 'dnf -y install postgresql-server postgresql-contrib', 300;
    # configure the firewall
    assert_script_run "firewall-cmd --permanent --add-service postgresql";
    assert_script_run "systemctl restart firewalld.service";
    # init the db
    if (script_run "/usr/bin/postgresql-setup --initdb") {
        # see if this is RHBZ #1872511...
        script_run "dnf -y install glibc-langpack-en", 180;
        assert_script_run "/usr/bin/postgresql-setup --initdb";
        record_soft_failure "postgresql-setup initially failed due to missing langpack - RHBZ #1872511";
    }
    # enable and start the systemd service
    assert_script_run "systemctl enable postgresql.service";
    assert_script_run "systemctl start postgresql.service";
    # create the owner
    assert_script_run 'su postgres -c "/usr/bin/createuser openqa"';
    # create the database
    assert_script_run 'su postgres -c "/usr/bin/createdb openqa -O openqa"';
    # set the password. oh, god, the quotes. THE QUOTES. trying to
    # get four layers of nested quotes properly escaped through
    # perl, bash and postgres is futile, so we write the command
    # to a file and call psql on the file
    assert_script_run 'echo "ALTER ROLE openqa WITH PASSWORD \'correcthorse\'" > /tmp/cmd';
    assert_script_run 'su postgres -c "psql openqa -f /tmp/cmd"';
    # adjust postgresql.conf to allow network connections; sloppy
    # version of how rolekit did it
    assert_script_run 'sed -i -e "s,.*listen_addresses *=.*,listen_addresses=\'*\',g" /var/lib/pgsql/data/postgresql.conf';
    # check that worked...
    upload_logs "/var/lib/pgsql/data/postgresql.conf";
    # adjust pg_hba.conf to use md5 authentication; sloppy version
    # of how rolekit did it
    assert_script_run 'sed -i -e "s,^host,#host,g" /var/lib/pgsql/data/pg_hba.conf';
    assert_script_run 'echo "host    all             all             all                     md5" >> /var/lib/pgsql/data/pg_hba.conf';
    # check that worked...
    upload_logs "/var/lib/pgsql/data/pg_hba.conf";
    # restart the service
    assert_script_run "systemctl restart postgresql.service";
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
    # once child jobs are done, decommission the server a bit
    assert_script_run 'su postgres -c "/usr/bin/dropdb -w --if-exists openqa"';
    assert_script_run 'su postgres -c "/usr/bin/dropuser -w --if-exists openqa"';
    # stop the server
    assert_script_run 'systemctl stop postgresql.service';
    # check server is stopped
    assert_script_run '! systemctl is-active postgresql.service';
    # FIXME check server is decommissioned...how?
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
