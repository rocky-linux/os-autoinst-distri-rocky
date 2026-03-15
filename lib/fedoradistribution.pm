package fedoradistribution;

use strict;

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
use testapi qw(check_var get_var send_key type_string assert_screen);

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
        $self->add_console('tty1-console', 'tty-console', {tty => 1});
        $self->add_console('tty2-console', 'tty-console', {tty => 2});
        $self->add_console('tty3-console', 'tty-console', {tty => 3});
        $self->add_console('tty4-console', 'tty-console', {tty => 4});
        $self->add_console('tty5-console', 'tty-console', {tty => 5});
        $self->add_console('tty6-console', 'tty-console', {tty => 6});
    }
}

sub x11_start_program {
    my ($self, $program, $timeout, $options) = @_;
    send_key "alt-f2";
    assert_screen "desktop_runner";
    type_string $program, 20;
    sleep 5;    # because of KDE dialog - SUSE guys are doing the same!
    send_key "ret", 1;
}

1;
# vim: set sw=4 et:
