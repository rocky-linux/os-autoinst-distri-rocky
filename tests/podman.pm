use base "installedtest";
use strict;
use lockapi;
use mmapi;
use tapnet;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->root_console(tty => 3);
    # on non-canned flavors, we need to install podman
    assert_script_run "dnf -y install podman", 180 unless (get_var("CANNED"));
    # check podman is installed
    assert_script_run "rpm -q podman";
    # check to see if you can pull an image from the registry
    assert_script_run "podman pull registry.fedoraproject.org/fedora:latest", 300;
    # run hello-world to test
    validate_script_output "podman run -it registry.fedoraproject.org/fedora:latest echo Hello-World", sub { m/Hello-World/ };
    # create a Dockerfile
    assert_script_run 'printf \'FROM registry.fedoraproject.org/fedora:latest\nRUN /usr/bin/dnf install -y httpd\nEXPOSE 80\nCMD ["-D", "FOREGROUND"]\nENTRYPOINT ["/usr/sbin/httpd"]\n\' > Dockerfile';
    # Build an image
    assert_script_run 'podman build -t fedora-httpd $(pwd)', 180;
    # Verify the image
    validate_script_output "podman images", sub { m/fedora-httpd/ };
    # Run the container
    assert_script_run "podman run -d -p 80:80 localhost/fedora-httpd";
    # Verify the container is running
    validate_script_output "podman container ls", sub { m/fedora-httpd/ };
    # Test apache is working
    assert_script_run "curl http://localhost";
    # Open the firewall, except on CoreOS where it's not installed
    unless (get_var("SUBVARIANT") eq "CoreOS") {
        assert_script_run "firewall-cmd --permanent --zone=internal --add-interface=cni-podman0";
        assert_script_run "firewall-cmd --permanent --zone=internal --add-port=80/tcp";
    }
    # tell client we're ready and wait for it to send the message
    mutex_create("podman_server_ready");
    my $children = get_children();
    my $child_id = (keys %$children)[0];
    mutex_lock("podman_connect_done", $child_id);
    mutex_unlock("podman_connect_done");
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
