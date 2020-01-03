package fedoradistribution;
use base 'distribution';
use Cwd;

# Fedora distribution class

# Distro-specific functions, that are actually part of the API
# (and it's completely up to us to implement them) should be here

# functions that can be reimplemented:
# ensure_installed
# x11_start_program
# become_root
# script_sudo
# type_password

# importing whole testapi creates circular dependency, so import only
# necessary functions from testapi
use testapi qw(check_var get_var send_key type_string wait_idle assert_screen);

sub init() {
    my ($self) = @_;

    $self->SUPER::init();
    # Initialize the first virtio serial console as "virtio-console"
    if (check_var('BACKEND', 'qemu')) {
        $self->add_console('virtio-console', 'virtio_terminal', {});
        for (my $num = 1; $num < get_var('VIRTIO_CONSOLE_NUM', 1); $num++) {
            # initialize second virtio serial console as
            # "virtio-console1", third as "virtio-console2" etc.
            $self->add_console('virtio-console' . $num, 'virtio_terminal', {socked_path => cwd() . '/virtio_console' . $num});
        }
    }
}

sub x11_start_program {
    my ($self, $program, $timeout, $options) = @_;
    send_key "alt-f2";
    assert_screen "desktop_runner";
    type_string $program, 20;
    sleep 5; # because of KDE dialog - SUSE guys are doing the same!
    send_key "ret", 1;
}

1;
# vim: set sw=4 et:
