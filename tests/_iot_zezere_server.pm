use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # deploy a zezere (Fedora IoT provisioning server) instance
    assert_script_run "dnf --enablerepo=updates-testing -y install zezere", 180;
    # write config file
    assert_script_run "printf '[global]\nsecret_key = SECRET_KEY\ndebug = yes\nallowed_hosts = localhost, localhost.localdomain, 172.16.2.118\nauth_method = local\n\n[oidc.rp]\nsign_algo = RS256\n\n[database]\nengine = django.db.backends.sqlite3\nname = /var/local/zezere.sqlite3' > /etc/zezere.conf";
    # write systemd unit file
    assert_script_run "printf '[Unit]\nDescription=Zezere provisioning server\n\n[Service]\nExecStart=/usr/bin/zezere-manage runserver 172.16.2.118:80\n\n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/zezere.service";
    assert_script_run "systemctl daemon-reload";
    # open firewall port
    assert_script_run "firewall-cmd --add-service=http";
    # update DB schema
    assert_script_run "zezere-manage makemigrations";
    assert_script_run "zezere-manage migrate";
    # load DB fixtures
    assert_script_run "zezere-manage loaddata fedora_iot_runreqs";
    assert_script_run "zezere-manage loaddata fedora_installed";
    # create admin user
    assert_script_run 'zezere-manage createsuperuser --username admin --email zezere@test.openqa.fedoraproject.org --no-input';
    # set admin password (can't find a non-interactive way sadly)
    type_string "zezere-manage changepassword admin\n";
    sleep 2;
    type_string "weakpassword\n";
    sleep 2;
    type_string "weakpassword\n";
    sleep 2;
    # check DB exists
    assert_script_run "ls -l /var/local/zezere.sqlite3";
    # start server
    assert_script_run "systemctl start zezere.service";
    # check it seems to be running
    assert_script_run "curl http://172.16.2.118";
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
