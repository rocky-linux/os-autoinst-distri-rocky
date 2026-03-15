# does a basic test of toolbox
use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $version_major = get_version_major();
    assert_script_run "dnf install toolbox --assumeyes", 360 unless (get_var("CANNED"));
    assert_script_run "rpm -q toolbox";
    assert_script_run "toolbox -y create container_rl --image docker.io/rockylinux/rockylinux:${version_major}", 300;
    assert_script_run "toolbox list | grep container_rl";
    validate_script_output "toolbox run --container container_rl uname -a", sub { m/Linux toolbx/ };
    validate_script_output "toolbox run --container container_rl cat /etc/rocky-release", sub { m/Rocky Linux release $version_major/ };
    type_string "toolbox enter container_rl\n";
    assert_screen "console_in_toolbox", 180;
    type_string "exit\n";
    sleep 5;
    assert_script_run "clear";
    assert_script_run 'podman stop container_rl';
    assert_script_run "toolbox rm container_rl";
    assert_script_run "toolbox rmi --all --force";
    # pull fedora here as a quick test
    assert_script_run "toolbox -y create --distro fedora --release 39", 300;
    type_string "toolbox enter fedora-toolbox-39\n";
    assert_screen "console_in_toolbox", 180;
    type_string "exit\n";
    sleep 5;
    validate_script_output "toolbox run --distro fedora --release 39 cat /etc/fedora-release", sub { m/Fedora release 39 \(Thirty Nine\)/ };
    # clean up
    assert_script_run 'podman stop fedora-toolbox-39';
    assert_script_run "toolbox rm fedora-toolbox-39";
    assert_script_run "toolbox rmi --all --force";
}

sub test_flags {
    return {fatal => 1};
}

1;
