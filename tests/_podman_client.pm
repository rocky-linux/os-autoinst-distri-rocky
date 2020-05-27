use base "installedtest";
use strict;
use lockapi;
use mmapi;
use tapnet;
use testapi;
use utils;

sub run {
    my $self = shift;
    bypass_1691487 unless (get_var("DESKTOP"));
    $self->root_console(tty=>3);
    # wait for server to be set up
    mutex_lock "podman_server_ready";
    mutex_unlock "podman_server_ready";
    # connect to server then tell server we're done
    my $ret = script_run "curl http://10.0.2.114";
    mutex_create "podman_connect_done";
    # die if connection failed
    die "connection failed!" if ($ret);
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
